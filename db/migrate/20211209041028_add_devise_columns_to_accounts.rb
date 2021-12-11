class AddDeviseColumnsToAccounts < ActiveRecord::Migration[6.0]
  def change
    ## Database authenticatable
    reversible do |dir|
      dir.up do
        Account.where(email: nil).update_all(email: "")
        Account.where(login: nil).update_all(login: "")
        change_column :accounts, :email, :string, null: false, default: ""
        change_column :accounts, :login, :string, null: false, default: ""
      end

      dir.down do
        change_column :accounts, :email, :string, null: true, default: nil
        change_column :accounts, :login, :string, null: true, default: nil
      end
    end
    rename_column :accounts, :password, :legacy_encrypted_password
    add_column :accounts, :encrypted_password, :string, null: false, default: ""

    ## Recoverable
    add_column :accounts, :reset_password_token, :string
    add_column :accounts, :reset_password_sent_at, :datetime

    ## Trackable
    add_column :accounts, :sign_in_count, :integer, default: 0, null: false
    add_column :accounts, :current_sign_in_at, :datetime
    add_column :accounts, :last_sign_in_at, :datetime
    add_column :accounts, :current_sign_in_ip, :string
    add_column :accounts, :last_sign_in_ip, :string

    ## Index
    add_index :accounts, :login,                unique: true
    add_index :accounts, :email,                unique: true
    add_index :accounts, :reset_password_token, unique: true
  end
end
