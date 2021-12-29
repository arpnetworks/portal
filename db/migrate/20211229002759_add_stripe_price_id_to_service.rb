class AddStripePriceIdToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :stripe_price_id, :string, null: false, default: ''
  end
end
