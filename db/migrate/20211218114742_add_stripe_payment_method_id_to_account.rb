class AddStripePaymentMethodIdToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :stripe_payment_method_id, :string, null: false, default: ""
  end
end
