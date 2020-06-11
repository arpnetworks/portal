class AddDerivedKeySaltToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :dk_salt, :string, limit: 32
  end
end
