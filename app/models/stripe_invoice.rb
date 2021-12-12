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

  def self.create_payment(account, invoice)
    inv = Invoice.find_by(stripe_invoice_id: invoice['id'])

    if inv
      inv.payments.create(
        account: account,
        reference_number: '',
        date: Time.at(invoice['status_transitions']['paid_at']),
        method: 'Stripe',
        amount: invoice['total']
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
