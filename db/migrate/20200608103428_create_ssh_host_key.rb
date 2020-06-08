class CreateSshHostKey < ActiveRecord::Migration
  def change
    create_table :ssh_host_keys do |t|
      t.references 'virtual_machine', index: true
      t.text     'key'
      t.string   'fingerprint_md5',    limit: 255
      t.string   'fingerprint_sha256', limit: 255
      t.string   'key_type',           limit: 64
      t.timestamps
    end
  end
end
