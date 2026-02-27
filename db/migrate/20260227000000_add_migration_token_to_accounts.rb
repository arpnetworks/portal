class AddMigrationTokenToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :migration_token, :string
    add_index :accounts, :migration_token, unique: true
  end
end
