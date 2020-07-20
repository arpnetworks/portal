#!/usr/bin/env ruby
#
# Author: Garry
# Date  : 10-03-2010
#
# Utility to delete a VPS account

# If we're running this from Spring, we'll already have APP_PATH
unless Object.const_defined?(:APP_PATH)
  # Rails
  APP_PATH = File.expand_path('../../../config/application', __dir__)
  require_relative '../../../config/boot'
  require APP_PATH
  Rails.application.require_environment!
end

def usage
  puts './cancel_vps.rb <UUID>'
end

def instantiate_ip_blocks(service)
  # If no IP blocks are associated with this service, find the first service
  # with code of IP_BLOCK and use it instead.  Code similar to this is
  # duplicated in admin/services_controller.rb.  We should find some common
  # place to put it.
  if service.ip_blocks.empty?
    sc_id = (o = ServiceCode.find_by(name: 'IP_BLOCK')) && o.id
    @ip_block_service = @service.account.services.active.find_by(service_code_id: sc_id).ip_blocks
  else
    @ip_block_service = service.ip_blocks
  end

  @ip_blocks = @ip_block_service.sort do |a, b|
    a.version <=> b.version # IPv4 to appear before IPv6
  end
end

def ip_blocks_report(ip_blocks)
  s = ''

  ip_blocks.each do |block|
    s += "IPv#{block.version}: #{block.cidr}\n"
  end

  s
end

def num_of_virtual_machines(account)
  i = 0

  account.services.active.each do |service|
    i += 1 if service.service_code.name == 'VPS'
  end

  i
end

def yesno(s)
  print s

  yn = STDIN.gets.chomp

  yn.downcase == 'y'
end

if ARGV.size < 1
  usage
  exit 1
end

@UUID = ARGV[0]
@hostname = `hostname`.chomp

@vm = VirtualMachine.find_by(uuid: @UUID)

unless @vm
  puts "Cannot find VM with UUID #{@UUID}"
  exit 1
end

@account = @vm.account
@service = @vm.resource.service

if (i = num_of_virtual_machines(@account)) > 1
  puts "The account '#{@account.display_account_name}' has #{i} VMs, so this script cannot be used."
  exit 1
end

instantiate_ip_blocks(@service)

@vlan = @ip_blocks.first.vlan
@location = @ip_blocks.first.location.code

puts <<~EOF
  The following VM will be deleted:

  VM UUID: #{@vm.uuid}
  VM Host: #{@vm.host}
  VM Label: #{@vm.label}

  Account Owner: #{@account.display_account_name}
  Account Email: #{@account.email}

  The following IP blocks are allocated to this customer:

  #{ip_blocks_report(@ip_blocks)}
  VLAN: #{@vlan}
  Location: #{@location}

EOF

if yesno 'Cancel this VPS? [y/N] : '
  if Rails.env.production? && @hostname == $HOST_PORTAL
    puts ''
    puts "Running #{$CANCEL_SCRIPT} on host '#{@vm.host}'..."
    system("ssh #{@vm.host} #{$CANCEL_SCRIPT} #{@vm.uuid}")

    puts ''
    puts "Running #{$HOST_CACTI_DESTROY_VLAN_SCRIPT}..."
    system("ssh -t -A #{$HOST_RANCID} 'cd #{$HOST_RANCID_DIR} && #{$HOST_CACTI_DESTROY_VLAN_SCRIPT} #{@vlan} #{@location}'")
  end

  @ip_blocks.each do |ip_block|
    next unless ip_block.version == 4 && ip_block.cidr_obj.bits <= 29

    puts ''
    puts "Sending removal SWIP to ARIN for #{ip_block.cidr}..."

    @form = OpenStruct.new
    @form.registration_action = 'R'
    @form.network_name = ip_block.arin_network_name
    @downstream_org = ip_block.resource.service.account
    @downstream_org.instance_eval do
      def public_comments
        ''
      end
    end

    Mailer.swip_reassign_simple(@form, @downstream_org, ip_block).deliver_now if Rails.env.production?
  end

  puts ''
  puts 'Deleting VM service record...'
  @vm.resource.service.destroy

  if @ip_blocks.first.resource
    puts ''
    puts 'Deleting IP service record...'
    @ip_blocks.first.resource.service.destroy
  end

  @account.bandwidth_quotas.each do |bq|
    puts ''
    puts 'Deleting Bandwidth Quota service record...'
    bq.resource.service.destroy
  end

  if @account.mrc == 0
    puts ''
    puts 'Deleting Credit Card records...'

    ccs = @account.credit_cards

    ccs.each do |cc|
      cc&.destroy
    end
  end

  @account.unsuspend!

  @account.updated_at = Time.now
  @account.save
end
