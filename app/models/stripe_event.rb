class StripeEvent < ApplicationRecord
  def supported_events
    %w[
      invoice.finalized
      invoice.paid
      invoice.payment_action_required
      invoice.payment_failed
      invoice.payment_succeeded
      payment_method.attached
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
      account, _invoice = get_account_and_invoice(body) rescue nil
      account
    when :invoice
      begin
        _account, invoice = get_account_and_invoice(body)
        Invoice.find_by(stripe_invoice_id: invoice['id'])
      rescue
      end
    end
  end

  def self.process!(event, payload)
    stripe_event = StripeEvent.create(
      event_id: event.id, event_type: event.type, status: 'received', body: payload
    )
    stripe_event.go!
  end

  ##################
  # EVENT HANDLERS #
  ##################

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

    StripeInvoice.create_payment(account, invoice)
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
      if !account.offload_billing?
        # Gotta do this manually for now
        Mailer.simple_notification("CC: Migrate #{account.display_account_name} (#{account.id}) subscriptions to Stripe", "").deliver_now
      end

      account.stripe_payment_method_id = payment_method['id']
      account.save
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
