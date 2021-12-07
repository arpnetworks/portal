class CreateStripeEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_events do |t|
      t.string :event_id
      t.string :event_type, limit: 128
      t.string :status, limit: 64

      t.text :body

      t.timestamps
    end
  end
end
