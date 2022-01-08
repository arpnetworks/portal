class StripeInvoice < Invoice
  def create_line_items(stripe_line_items)
    stripe_line_items.each do |li|
      @code = begin
        product = Stripe::Product.retrieve(id: li['price']['product'])
        product.metadata.product_code
      rescue StandardError
        'MISC'
      end

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
    inv.create_line_items(invoice['lines']['data'])
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
        date: Time.at(invoice['status_transitions']['paid_at']),
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
      payment.notes = 'Refunded on ' + charge_refunded_on(charge)
      payment.save
    end

    refunded_amount
  end

  def self.charge_refunded_on(charge)
    Time.at(charge['refunds']['data'].first['created']).to_s
  rescue StandardError
    ''
  end

  def self.charge_refunded_amount(charge)
    total = charge['refunds']['data'].inject(0) do |x, refund|
      x + (refund['status'] == 'succeeded' ? refund['amount'] : 0)
    end

    total / 100.00
  end
end
