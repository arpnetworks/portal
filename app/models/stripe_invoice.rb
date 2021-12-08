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
end
