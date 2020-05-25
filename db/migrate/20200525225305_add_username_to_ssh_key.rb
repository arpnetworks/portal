class AddUsernameToSshKey < ActiveRecord::Migration
  def change
    add_column :ssh_keys, :username, :string
  end
end
