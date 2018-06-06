class VirtualMachinesInterface < ActiveRecord::Base
  belongs_to :virtual_machine

  validates_uniqueness_of :mac_address
end
