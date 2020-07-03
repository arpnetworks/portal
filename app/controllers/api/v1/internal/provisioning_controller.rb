class Api::V1::Internal::ProvisioningController < ApiController
  before_action :trusted_hosts
  before_action :find_virtual_machine, only: [:config]

  def config
    @vm_base = Rails.root + $PROVISIONING['vm_base']

    @ip_address   = @virtual_machine.ip_address
    @ipv6_address = @virtual_machine.ipv6_address
    @gateway      = @account.network_settings_for(@ip_address)[0]

    @ipv6_first   = @ipv6_address.sub(/::.*/, '')
    @ipv6_last    = @ipv6_address.sub(/.*::(.*)$/, '\1')

    @make_config = @vm_base + $PROVISIONING['scripts']['make_config']

    res = system(@make_config,
                 @interface.mac_address,
                 @interface.ip_address,
                 @interface.ip_netmask,
                 @gateway,
                 @ipv6_first,
                 @ipv6_last,
                 @virtual_machine.label,
                 $PROVISIONING['host_suffix'],
                 @virtual_machine.os_template,
                 @virtual_machine.vnc_password)

    if !res
      render :text => "#{$PROVISIONING['scripts']['make_config']} exited with non-zero status\n", :status => 500
      return
    end

    @filename = "#{@mac}.tar.gz"
    @filename_fullpath = @vm_base + "/serve/" + @filename

    res = system("tar",
                 "czvf", @filename_fullpath,
                 "-C",   @vm_base + "/configs/#{@mac}",
                 "--owner=0", "--group=0",
                 ".")

    send_file(@filename_fullpath, :filename => @filename)
  end

  private

  def find_virtual_machine
    @mac = params[:mac_address]

    mac_with_colons = @mac[0..1].to_s + ':' +
                      @mac[2..3].to_s + ':' +
                      @mac[4..5].to_s + ':' +
                      @mac[6..7].to_s + ':' +
                      @mac[8..9].to_s + ':' +
                      @mac[10..11].to_s

    begin
      @interface = VirtualMachinesInterface.find_by_mac_address(mac_with_colons)

      raise ActiveRecord::RecordNotFound if !@interface
    rescue ActiveRecord::RecordNotFound
      render :text => "Virtual Machine with MAC #{@mac} not found\n", :status => 404
      return
    end

    @virtual_machine = @interface.virtual_machine
    @account = @virtual_machine.account
  end

  def trusted_hosts
    trusted_vm_hosts
  end
end
