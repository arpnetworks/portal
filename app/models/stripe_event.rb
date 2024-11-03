class StripeEvent < ApplicationRecord
  def supported_events
    %w[
      charge.refunded
      customer.subscription.created
      invoice.finalized
      invoice.paid
      invoice.payment_action_required
      invoice.payment_failed
      payment_method.attached
      setup_intent.succeeded
      setup_intent.created
    ]
  end

  def go!
    raise StandardError, 'Attempt to handle event already processed' if processed?
    raise ArgumentError, "Unsupported event '#{event_type}'" unless supported_events.include?(event_type)

    begin
      handler = 'handle_' + event_type.gsub('.', '_') + '!'
      send(handler)
      handled!
    rescue NoMethodError => e
      raise ArgumentError, "No handler found for event '#{event_type}'"
    end
  end

  def processed?
    status == 'processed'
  end

  def handled!
    self.status = 'processed'
    save
  end

  # Attempts to introspect the body of the event to pull out related data that ties
  # back to our models
  def related(model)
    case model
    when :account
      begin
        account, _invoice = get_account_and_invoice(body)
      rescue StandardError
        nil
      end
      account
    when :invoice
      begin
        _account, invoice = get_account_and_invoice(body)
        Invoice.find_by(stripe_invoice_id: invoice['id'])
      rescue StandardError
      end
    end
  end

  def self.process!(event, payload)
    stripe_event = StripeEvent.create(
      event_id: event.id, event_type: event.type, status: 'received', body: payload
    )
    Stripe::EventProcessorJob.perform_later(stripe_event.id)
  end

  ##################
  # EVENT HANDLERS #
  ##################

  def handle_charge_refunded!
    raise 'Incorrect event type' if event_type != 'charge.refunded'

    event = JSON.parse(body)

    charge = event['data']['object']
    customer_id = charge['customer']
    receipt_url = charge['receipt_url']

    account = Account.find_by(stripe_customer_id: customer_id)

    refunded_amount = StripeInvoice.process_refund(charge)

    begin
      Mailers::Stripe.refund(account, refunded_amount, receipt_url: receipt_url).deliver_later
    rescue StandardError => e
      Mailer.simple_notification("CC: Was unable to send refund receipt email to #{account.display_account_name}",
                                 e.message).deliver_later
    end
  end

  def handle_customer_subscription_created!
    raise 'Incorrect event type' if event_type != 'customer.subscription.created'

    event = JSON.parse(body)

    subscription = event['data']['object']
    subscription['items']['data'].each do |si|
      next unless (service_id = si['metadata']['link_to_service_id'])

      begin
        service = Service.find(service_id.to_i)
        service.stripe_subscription_item_id = si['id']
        service.save
      rescue ActiveRecord::RecordNotFound
      end
    end
  end

  def handle_invoice_finalized!
    raise 'Incorrect event type' if event_type != 'invoice.finalized'

    account, invoice = get_account_and_invoice(body)

    @metadata_invoice_id = invoice['metadata']['link_to_invoice_id']
    if @metadata_invoice_id
      StripeInvoice.link_to_invoice(@metadata_invoice_id, invoice)
      return
    end

    inv = StripeInvoice.create_for_account(account, invoice)
  end

  def handle_invoice_paid!
    raise 'Incorrect event type' if event_type != 'invoice.paid'

    account, invoice = get_account_and_invoice(body)

    stripe_invoice = StripeInvoice.create_payment(account, invoice)

    begin
      hosted_invoice_url = invoice['hosted_invoice_url']
      Mailers::Stripe.sales_receipt(stripe_invoice, hosted_invoice_url: hosted_invoice_url).deliver_later
    rescue StandardError => e
      Mailer.simple_notification("CC: Was unable to send sales receipt email to #{account.display_account_name}",
                                 e.message).deliver_later
    end
  end

  def handle_invoice_payment_failed!
    raise 'Incorrect event type' if event_type != 'invoice.payment_failed'

    account, invoice = get_account_and_invoice(body)
    hosted_invoice_url = invoice['hosted_invoice_url']

    Mailers::Stripe.payment_failed(account, hosted_invoice_url: hosted_invoice_url).deliver_later
  end

  def handle_payment_method_attached!
    raise 'Incorrect event type' if event_type != 'payment_method.attached'

    event = JSON.parse(body)

    payment_method = event['data']['object']
    customer_id = payment_method['customer']

    if customer_id
      Stripe::Customer.update(customer_id, {
                                invoice_settings: {
                                  default_payment_method: payment_method['id']
                                }
                              })
    end

    account = Account.find_by(stripe_customer_id: customer_id)
    if account
      unless account.offload_billing?
        # Gotta do this manually for now
        Mailer.simple_notification(
          "CC: Migrate #{account.display_account_name} (#{account.id}) subscriptions to Stripe", ''
        ).deliver_later
      end

      account.stripe_payment_method_id = payment_method['id']
      account.save
    end
  end

  def handle_setup_intent_created!
    raise 'Incorrect event type' if event_type != 'setup_intent.created'

    event = JSON.parse(body)
    setup_intent = event['data']['object']
    metadata = setup_intent['metadata']

    # At the moment, we don't do anything with this event besides logging it
  end

  def handle_setup_intent_succeeded!
    raise 'Incorrect event type' if event_type != 'setup_intent.succeeded'

    event = JSON.parse(body)
    setup_intent = event['data']['object']
    metadata = setup_intent['metadata']

    # This SetupIntent originated from the new order wizard, so send us a notification
    if metadata['source'] == 'new_order_wizard'
      os = VirtualMachine.os_display_name_from_code($CLOUD_OS, metadata['product_operating_system_code'], version: true) rescue ''

      product = {
        code: metadata['product_code'],
        description: metadata['product_description'],
        os: os,
        os_code: metadata['product_operating_system_code'],
        location: metadata['product_location'],
        ip_block: metadata['product_ip_block']
      }

      customer = {
        name: metadata['customer_first_name'] + ' ' + metadata['customer_last_name'],
        email: metadata['customer_email'],
        company: metadata['customer_company'] || ''
      }

      Mailer.new_order_from_stripe(setup_intent['id'], product, customer).deliver_later
    end
  end

  def get_account_and_invoice(body)
    event = JSON.parse(body)

    invoice     = event['data']['object']
    customer_id = invoice['customer']

    account = Account.find_by(stripe_customer_id: customer_id)

    raise "No account found given Stripe customer ID: #{customer_id}" if account.nil?

    [account, invoice]
  end
end
