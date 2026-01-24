class ConvertStripeEventsToUtf8 < ActiveRecord::Migration[6.0]
  def up
    # Convert the entire stripe_events table to utf8 to match the rest of the database
    execute "ALTER TABLE stripe_events CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci"
  end

  def down
    # Revert back to latin1 (this may cause data loss for any special characters)
    execute "ALTER TABLE stripe_events CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci"
  end
end
