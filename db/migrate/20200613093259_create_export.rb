class CreateExport < ActiveRecord::Migration
  def change
    create_table :exports do |t|
      t.datetime 'exported_at'
      t.integer  'records'
      t.string   'record_type', limit: 128
    end
  end
end
