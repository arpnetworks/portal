class AddDeviseTwoFactorToAccounts < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :encrypted_otp_secret, :string
    add_column :accounts, :encrypted_otp_secret_iv, :string
    add_column :accounts, :encrypted_otp_secret_salt, :string
    add_column :accounts, :consumed_timestep, :integer
    add_column :accounts, :otp_required_for_login, :boolean, null: false, default: false
    add_column :accounts, :otp_backup_codes, :text, array: true
  end
end
