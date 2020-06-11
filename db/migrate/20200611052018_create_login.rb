class CreateLogin < ActiveRecord::Migration
  def change
    create_table :logins do |t|
      t.references 'virtual_machine', index: true
      t.string :username, limit: 64
      t.string :password, limit: 255
      t.string :iv,       limit: 64

      t.timestamps
    end
  end
end
