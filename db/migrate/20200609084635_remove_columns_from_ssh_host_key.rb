class RemoveColumnsFromSshHostKey < ActiveRecord::Migration
  def change
    remove_column :ssh_host_keys, :key_type, :string
  end
end
