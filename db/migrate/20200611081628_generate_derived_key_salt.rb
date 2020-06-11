class GenerateDerivedKeySalt < ActiveRecord::Migration
  def change
    Account.all.each do |account|
      account.update_column(:dk_salt, SecureRandom.alphanumeric(16))
    end
  end
end
