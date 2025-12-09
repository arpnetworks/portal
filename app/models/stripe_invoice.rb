# Handles Stripe invoice creation and synchronization with the ARP billing system.
# Supports pagination for invoices with more than 10 line items using Stripe's auto_paging_each API.
class StripeInvoice < Invoice
  def create_line_items(stripe_line_items, opts = {})
    stripe_line_items.each do |li|
      @code = begin
        product = Stripe::Product.retrieve(id: li['price']['product'])
        product.metadata.product_code
      rescue StandardError
        'MISC'
      end

      # When we create an invoice manually, Stripe doesn't append the quantity
      # to the description
      li['description'] = "#{li['quantity']} × #{li['description']}" if opts[:billing_reason] == 'manual'

      line_items.create(code: @code,
                        description: li['description'],
                        amount: li['amount'] / 100.0)

      discount_amounts = li['discount_amounts']
      create_discount_line_items(@code, discount_amounts) if discount_amounts
    end
  end

  def create_discount_line_items(code, stripe_discount_amounts)
    stripe_discount_amounts.each do |discount|
      line_items.create(code: code, amount: -1.0 * (discount['amount'] / 100.0), description: 'Discount')
    end

    # If we ever want to: invoice['discount']['coupon']['name'] + ['percent_off']
  end

  def self.create_for_account(account, invoice)
    inv = create(account: account, stripe_invoice_id: invoice['id'])
    all_line_items = fetch_all_line_items(invoice)
    inv.create_line_items(all_line_items, billing_reason: invoice['billing_reason'])
  end

  def self.link_to_invoice(arp_invoice_id, invoice)
    raise "Invoice ID #{arp_invoice_id} missing" unless arp_invoice_id

    begin
      inv = Invoice.find(arp_invoice_id)
      inv.stripe_invoice_id = invoice['id']
      inv.save
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError, "Provided Invoice ID #{arp_invoice_id} does not exist, cannot link Stripe invoice"
    end
  end

  def self.create_payment(account, invoice)
    inv = Invoice.find_by(stripe_invoice_id: invoice['id'])

    if inv
      inv.payments.create(
        account: account,
        reference_number: invoice['id'],
        date: Time.zone.at(invoice['status_transitions']['paid_at']),
        method: 'Stripe',
        amount: invoice['total'] / 100.0
      )

      if invoice['paid'] == true
        inv.paid = true
        inv.save
      end
    else
      raise "Invoice not found by Stripe invoice ID: #{invoice['id']}"
    end

    inv
  end

  def self.process_refund(charge)
    inv = Invoice.find_by(stripe_invoice_id: charge['invoice'])

    refunded_amount = charge_refunded_amount(charge)

    raise "Invoice not found by Stripe invoice ID: #{charge['invoice']['id']}" unless inv
    raise 'Invoice paid amount does not equal refunded amount' if inv.paid != refunded_amount

    inv.paid = false
    inv.save

    inv.payments.each do |payment|
      payment.amount = 0
      payment.notes = "Refunded on #{charge_refunded_on(charge)}"
      payment.save
    end

    refunded_amount
  end

  def self.charge_refunded_on(charge)
    Time.zone.at(charge['refunds']['data'].first['created']).to_s
  rescue StandardError
    ''
  end

  def self.charge_refunded_amount(charge)
    total = charge['refunds']['data'].inject(0) do |x, refund|
      x + (refund['status'] == 'succeeded' ? refund['amount'] : 0)
    end

    total / 100.00
  end

  # Private helper methods

  def self.fetch_all_line_items(invoice)
    # Retrieve all line items, handling pagination if needed
    # Stripe webhook payloads include max 10 items; invoices can have unlimited items
    if invoice['lines']['has_more']
      # Invoice has more than 10 items, need to retrieve all via API
      fetch_line_items_from_api(invoice)
    else
      # Invoice has 10 or fewer items, use embedded data (no API call needed)
      invoice['lines']['data']
    end
  end
  private_class_method :fetch_all_line_items

  def self.fetch_line_items_from_api(invoice)
    all_line_items = []

    begin
      full_invoice = Stripe::Invoice.retrieve(
        invoice['id'],
        expand: ['lines']
      )

      # Use auto_paging_each to automatically handle pagination
      full_invoice.lines.auto_paging_each do |line_item|
        all_line_items << line_item
      end
    rescue StandardError => e
      unless Rails.env.test?
        Rails.logger.warn "Could not retrieve all line items for invoice #{invoice['id']}, " \
                          "may be incomplete: #{e.message}"
      end
      all_line_items = invoice['lines']['data']
    end

    all_line_items
  end
  private_class_method :fetch_line_items_from_api
end
