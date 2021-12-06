class AddStripeCustomerIdToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :stripe_customer_id, :string
  end
end
