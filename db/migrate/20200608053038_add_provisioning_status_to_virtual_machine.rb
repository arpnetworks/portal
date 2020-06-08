class AddProvisioningStatusToVirtualMachine < ActiveRecord::Migration
  def change
    add_column :virtual_machines, :provisioning_status, :string, limit: 64
  end
end
