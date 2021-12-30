class AddStripeSubscriptionItemIdToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :stripe_subscription_item_id, :string, null: false, default: ''
  end
end
