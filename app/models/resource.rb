class Resource < ApplicationRecord
  belongs_to :service
  belongs_to :assignable, :polymorphic => :true

  # We don't use this yet, but might come in handy later
  def self.assignables
    [:virtual_machine, :ip_block, :bandwidth_quota, :backup_quota, :bgp_session]
  end
end
