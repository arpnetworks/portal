class AddStripeQuantityToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :stripe_quantity, :integer, null: false, default: 1
  end
end
