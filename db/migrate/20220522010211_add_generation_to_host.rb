class AddGenerationToHost < ActiveRecord::Migration[6.0]
  def change
    add_column :hosts, :generation, :string, null: false, default: '3'
  end
end
