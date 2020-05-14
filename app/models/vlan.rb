class Vlan < ActiveRecord::Base
  belongs_to :location

  def self.next_available(opts = {})
    start_at = (opts[:start_at] || 100).to_i
    limit    = (opts[:limit]    || 1).to_i
    location =  opts[:location] || 'lax'

    location_id = Location.find_by_code(location).id

    start_at = 1 if start_at < 1
    limit    = 1 if limit < 1

    all_vlans = []
    (start_at..4095).each do |vlan_id|
      if vlan_id >= start_at
        all_vlans << vlan_id
      end
    end

    available_vlans = all_vlans - in_use(location_id)
    available_vlans[0..limit-1]
  end

  # Return an array of all the VLANs in use, from both the VLAN database
  # and IpBlock#vlan entries
  def self.in_use(location_id)
    vlans_from_ip_blocks = IpBlock.all.select do |ip_block|
      if (loc = ip_block.location)
        loc.id == location_id
      else
        false
      end
    end
    vlans_from_ip_blocks = vlans_from_ip_blocks.map { |ip| ip.vlan }.compact

    vlans_from_vlan_database = Vlan.all.select do |ip_block|
      if (loc = ip_block.location)
        loc.id == location_id
      else
        false
      end
    end

    vlans_from_vlan_database = vlans_from_vlan_database.map { |vlan| vlan.vlan }.compact

    (vlans_from_ip_blocks | vlans_from_vlan_database).sort
  end

  def self.mark_shutdown!(virtual_machine_id, status)
    virtual_machine = VirtualMachine.find(virtual_machine_id)
    if virtual_machine
      account = virtual_machine.account

      if status
        account.suspend!
      else
        account.unsuspend!
      end
    end
  end
end
