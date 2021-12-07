class AddStripeInvoiceIdToInvoice < ActiveRecord::Migration[6.0]
  def change
    add_column :invoices, :stripe_invoice_id, :string
  end
end
