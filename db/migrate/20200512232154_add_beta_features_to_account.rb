class AddBetaFeaturesToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :beta_features, :boolean, :null => false, :default => false
    add_column :accounts, :beta_billing_exempt, :boolean, :null => false, :default => false
  end
end
