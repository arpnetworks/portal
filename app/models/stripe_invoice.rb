class StripeInvoice < Invoice
  def create_line_items(stripe_line_items)
    stripe_line_items.each do |li|
      @code = begin
                product = Stripe::Product.retrieve(id: li['price']['product'])
                product.metadata.product_code
              rescue
                'MISC'
              end

      line_items.create(code: @code,
                        description: li['description'],
                        amount: li['amount'] / 100)
    end
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
      raise ArgumentError.new "Provided Invoice ID #{arp_invoice_id} does not exist, cannot link Stripe invoice"
    end
  end

  def self.create_payment(account, invoice)
    inv = Invoice.find_by(stripe_invoice_id: invoice['id'])

    if inv
      inv.payments.create(
        account: account,
        reference_number: '',
        date: Time.at(invoice['status_transitions']['paid_at']),
        method: 'Stripe',
        amount: invoice['total'] / 100
      )

      if invoice['paid'] == true
        inv.paid = true
        inv.save
      end
    else
      raise "Invoice not found by Stripe invoice ID: #{invoice['id']}"
    end
  end
end
