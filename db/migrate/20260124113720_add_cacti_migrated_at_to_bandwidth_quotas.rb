class AddCactiMigratedAtToBandwidthQuotas < ActiveRecord::Migration[6.0]
  def change
    add_column :bandwidth_quotas, :cacti_migrated_at, :datetime
    add_index :bandwidth_quotas, :cacti_migrated_at
  end
end
