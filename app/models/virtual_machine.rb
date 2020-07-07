class VirtualMachine < ApplicationRecord
  include Resourceable
  include Textilizable

  has_many :virtual_machines_interfaces, dependent: :destroy
  has_many :ssh_host_keys, dependent: :destroy
  has_many :logins, dependent: :destroy

  belongs_to :pool, optional: true

  textilizable :notes

  cattr_reader :per_page
  @@per_page = 10

  validates_presence_of   :label
  validates_uniqueness_of :label, case_sensitive: false
  validates_format_of     :label, :with => /\A[a-zA-Z0-9\-]+\z/

  validates_presence_of   :host
  validates_presence_of   :ram
  validates_presence_of   :storage

  before_save      :assign_ports!

  after_initialize :dns_and_uuid!
  after_create     :auto_mac_address!
  after_save       :create_or_update_dns_records!
  after_destroy    :destroy_dns_records!

  def self.plans
    {
      "vps" => {
        "small" => {
          'name'    => 'Small',
          'ram'     => 1024,
          'storage' => 40,
          'bandwidth' => 2000,

          'mrc'     => 10
        },
        "medium" => {
          'name'    => 'Medium',
          'ram'     => 1536,
          'storage' => 40,
          'bandwidth' => 3000,

          'mrc'     => 15

        },
        "all-purpose" => {
          'name'    => 'All-Purpose',
          'ram'     => 2048,
          'storage' => 40,
          'bandwidth' => 4000,

          'mrc'     => 20

        },
        "large" => {
          'name'    => 'Large',
          'ram'     => 3072,
          'storage' => 80,
          'bandwidth' => 6000,

          'mrc'     => 30

        },
        "jumbo" => {
          'name'    => 'Jumbo',
          'ram'     => 4096,
          'storage' => 160,
          'bandwidth' => 8000,

          'mrc'     => 40

        },
        "the american" => {
          'name'    => '"The American"',
          'ram'     => 8192,
          'storage' => 240,
          'bandwidth' => 12000,

          'mrc'     => 60

        }
      },
      "thunder" => {
      }
    }
  end

  def validate
    if cluster
      if VirtualMachine.first(:conditions => \
                              ["host like '#{cluster}%' and vnc_port = ? and id != ?",
                               vnc_port, id])
        errors.add_to_base("VNC port #{vnc_port} is already in use in the #{cluster} cluster")
      end
      if VirtualMachine.first(:conditions => \
                              ["host like '#{cluster}%' and websocket_port = ? and id != ?",
                               websocket_port, id])
        errors.add_to_base("Websocket port #{websocket_port} is already in use in the #{cluster} cluster")
      end
      if VirtualMachine.first(:conditions => \
                              ["host like '#{cluster}%' and serial_port = ? and id != ?",
                               serial_port, id])
        errors.add_to_base("Serial port #{serial_port} is already in use in the #{cluster} cluster")
      end
    end
  end

  def dns_and_uuid!
    if label
      find_dns_records
    end

    if new_record? && uuid.nil?
      self.uuid = UUID.generate
    end
  end

  def auto_mac_address!
    # Really cheesy way of randomizing between old prefix and new...
    if rand(2) == 0
      prefix = "5" + (rand(5) * 2).to_s + ":00:00:"
    else
      prefix = "52:54:00:"
    end

    int = virtual_machines_interfaces[0]
    auto_mac = prefix + 3.times.map { '%02x' % rand(255) }.join(':')

    if int.nil?
      virtual_machines_interfaces.create(
        :mac_address => auto_mac
      )
    else
      if int.mac_address.empty?
        int.mac_address = auto_mac
        int.save
      end
    end
  end

  def assign_ports!
    if cluster
      if serial_port.nil?
        self.serial_port = VirtualMachine.next_available_ports(cluster, 'serial_port', 1).first
      end

      if vnc_port.nil?
        self.vnc_port = VirtualMachine.next_available_ports(cluster, 'vnc_port', 1).first
      end

      if websocket_port.nil?
        self.websocket_port = VirtualMachine.next_available_ports(cluster, 'websocket_port', 1).first
      end
    end

    # Are there any other VMs on this host belonging to this account?  If so, the conserver
    # password needs to be the same
    if !(neighbors = direct_neighbors).empty?
      one_neighbor_with_same_conserver_login = neighbors.select { |nei| nei.console_login == console_login }.first

      if !(nei = one_neighbor_with_same_conserver_login).nil?
       self.conserver_password = nei.conserver_password
      end
    end
  end

  def create_or_update_dns_records!
    if ip_address
      if account.id > 1
        arpnetworks_domain = DnsDomain.find_by_name('arpnetworks.com')

        if arpnetworks_domain
          if @ipv4_dns_record &&
             (@ipv4_dns_record.name != dns_record_name ||
              @ipv4_dns_record.content != ip_address)
            @ipv4_dns_record.update_attributes(
              :name => dns_record_name,
              :content => ip_address
            )
            @ipv4_dns_record.save
          else
            if DnsRecord.find_by_name_and_type(dns_record_name, 'A') == nil
              arpnetworks_domain.records.create(
                :name => dns_record_name,
                :type => 'A',
                :content => ip_address
              )
            end
          end

          if ipv6_address
            if @ipv6_dns_record &&
               (@ipv6_dns_record.name != dns_record_name ||
                @ipv6_dns_record.content != ipv6_address)
              @ipv6_dns_record.update_attributes(
                :name => dns_record_name,
                :content => ipv6_address
              )
              @ipv6_dns_record.save
            else
              if DnsRecord.find_by_name_and_type(dns_record_name, 'AAAA') == nil
                arpnetworks_domain.records.create(
                  :name => dns_record_name,
                  :type => 'AAAA',
                  :content => ipv6_address
                )
              end
            end
          end
        end
      end
    end

    find_dns_records

    # In case serial console password was changed
    build_and_reload_conserver!

    if saved_change_to_host?
      build_and_reload_conserver(host_before_last_save.split('.')[0]) rescue nil
    end
  end

  def destroy_dns_records!
    @ipv4_dns_record.destroy if @ipv4_dns_record
    @ipv6_dns_record.destroy if @ipv6_dns_record

    build_and_reload_conserver!
  end

  def dns_record_name(alternate_label = nil)
    if alternate_label
      self.label = alternate_label
    end

    "#{label}.cust.arpnetworks.com"
  end

  def find_dns_records
    @ipv4_dns_record = DnsRecord.find_by_name_and_type(dns_record_name, 'A')
    @ipv6_dns_record = DnsRecord.find_by_name_and_type(dns_record_name, 'AAAA')
  end

  # Methods to access the network interfaces of this VirtualMachine.
  # Right now, we assume to only have one interface, but we build it as
  # a has_many above b/c we may want to define more in the future.
  [:mac_address, :ip_address, :ip_netmask,
   :ipv6_address, :ipv6_prefixlen].each do |attrib|
    define_method(attrib) do
      virtual_machines_interfaces[0] &&
        virtual_machines_interfaces[0].send(attrib)
    end
    define_method("#{attrib}=") do |s|
      if virtual_machines_interfaces[0]
        virtual_machines_interfaces[0].send("#{attrib}=", s)
        virtual_machines_interfaces[0].save
      end
    end
  end

  def abbreviated_host
    host.split('.')[0]
  end

  def build_and_reload_conserver!
    build_and_reload_conserver(abbreviated_host) rescue nil
  end

  def set_advanced_parameter!(parameter, value)
    host = abbreviated_host

    case parameter
    when 'bios-serial', 'boot-menu', 'boot-device'

      job = {
        :class => 'SetParamWorker',
        :args  => [self.uuid, parameter, value],
        :jid   => SecureRandom.hex(12).to_s,
        :retry => true,
        :enqueued_at => Time.now.to_f.to_s,
        :created_at  => Time.now.to_f.to_s
      }

      ARP_REDIS.lpush("queue:#{host}", job.to_json);
    end
  end

  def set_iso!(iso, opts = {})
    host = abbreviated_host

    job = {
      :class => 'SetIsoWorker',
      :args  => [self.uuid, iso, opts[:legacy]],
      :jid   => SecureRandom.hex(12).to_s,
      :retry => true,
      :enqueued_at => Time.now.to_f.to_s,
      :created_at  => Time.now.to_f.to_s
    }

    ARP_REDIS.lpush("queue:#{host}", job.to_json);
  end

  def change_state!(state)
    host = abbreviated_host

    job = {
      :class => 'ChangeStateWorker',
      :args  => [self.uuid, state],
      :jid   => SecureRandom.hex(12).to_s,
      :retry => true,
      :enqueued_at => Time.now.to_f.to_s,
      :created_at  => Time.now.to_f.to_s
    }

    ARP_REDIS.lpush("queue:#{host}", job.to_json);
  end

  def set_ssh_host_key(key)
    return if key.blank?
    return if key == 'N/A' # cloud-init sometimes does this

    ssh_host_keys.create(key: key)
  end

  def destroy_ssh_host_keys
    ssh_host_keys.destroy_all
  end

  def cluster
    cluster = nil

    if host =~ /^k[cz]t.*/ || host =~ /^sct/
      cluster = host[0..2]
    end

    cluster
  end

  # Do we consider this VM to be an ARP Thunder™ branded machine?
  def thunder?
    service = resource.service

    if service
      if (code = service.service_code) && code.name == 'THUNDER'
        return true
      else
        return false
      end
    end

    false
  end

  def location
    h = Host.find_by_hostname(host)
    h && h.location
  end

  # A helper method to determine which VLAN this VM should run under
  def vlan
    h = Host.find_by_hostname(host)
    if h.nil?
      # Not the best solution, but we need to fallback to something
      return account.vlan
    end

    vl = account.vlan(:location => h.location)
    if vl.nil?
      # Not the best solution, but we need to fallback to something
      return account.vlan
    end

    vl
  end

  # Return VMs that reside on the same host as this VM and belong to the same account
  def direct_neighbors
    VirtualMachine.where(host: host).select do |vm|
      vm.account == account && vm.id != id
    end
  end

  def self.next_available_ports(cluster, port_type, how_many)
    if ! %w(kct kzt sct).include? cluster
      raise ArgumentError.new("Invalid cluster")
    end

    if ! %w(vnc_port serial_port websocket_port).include? port_type
      raise ArgumentError.new("Invalid port_type")
    end

    how_many = how_many.to_i
    if how_many < 1
      raise ArgumentError.new("how_many cannot be less than 1")
    end

    vms = VirtualMachine.select("#{port_type}, label").where("host like '#{cluster}%'")

    ports = vms.map { |vm| vm.send(port_type) }.compact
    ports.sort!

    first = ports.first
    last  = ports.last

    if first.nil?
      first = last = case port_type
      when 'vnc_port'
        $PORTS_MIN_VNC.to_i
      when 'serial_port'
        $PORTS_MIN_SERIAL.to_i
      when 'websocket_port'
        $PORTS_MIN_WS.to_i
      end
    end

    available = []
    (first..last).each { |n| available << (ports.include?(n) ? nil : n) }
    available = available.compact

    if available.empty?
      available << (last + 1)

      (how_many - 1).downto(0).each do |n|
        available << available.last + 1
      end
    end

    available[0..(how_many-1)]
  end

  def pool_name
    pool && pool.name
  end

  # The English (or other language) friendly version of VM status
  def display_status
    # Provisioning Status has priority
    if display_provisioning_status != 'Done'
      return display_provisioning_status
    end

    case status
    when 'running'
      'Running'
    when 'stopping'
      'Shutting Down'
    when 'shutoff'
      'Powered Off'
    else
      status
    end
  end

  # The English (or other language) friendly version of VM provisioning status
  def display_provisioning_status
    case provisioning_status.to_s
    when 'initializing'
      'Initializing'
    else
      'Done'
    end
  end

  def display_ip_address
    begin
      raise if virtual_machines_interfaces.empty?

      first_ip_address = virtual_machines_interfaces.first.ip_address
      raise if first_ip_address.blank?

      first_ip_address
    rescue StandardError => e
      'Not Available'
    end
  end

  def define!(opts = {})
    Jobs::DefineVM.new.perform({ :account_id => account.id, :vm => self }.to_json)
  end

  def create_volume!(opts = {})
    if opts[:blank]
      Jobs::CreateVolumeForVM.new.perform({ :account_id => account.id, :vm => self }.to_json)
    else
      Jobs::CreateVolumeFromTemplateForVM.new.perform({ :account_id => account.id, :vm => self }.to_json)
    end
  end

  def create_config_disk!(opts = {})
    Jobs::CreateConfigDisk.new.perform({ vm: self, opts: opts }.to_json)
  end

  def create_login_records!(users, key)
    return if users.blank?

    users.each do |user|
      Login.set_credentials!(self, user['name'], user['password_plaintext'], key)
    end
  end

  # ****************************
  # ** This is the motherload **
  # ****************************
  #
  # Give it the desired VM specifications and a service to attach to and it'll handle the rest
  #
  def self.provision!(service, opts = {})
    # Where to put it
    @host     = opts[:host]
    @host_obj = Host.find_by_hostname(@host)

    # What resources it gets
    @ram     = opts[:ram]
    @storage = opts[:storage]
    @os_template = opts[:os_template]

    raise "Missing required parameter :host (where do I provision this?)"    unless @host
    raise "Missing required parameter :ram (amount of RAM in MB)"            unless @ram
    raise "Missing required parameter :storage (amount of primary HD in GB)" unless @storage
    raise "Missing required parameter :os_template"                          unless @os_template

    raise "Host #{@host} does not exist!" if @host_obj.nil?

    # Optional adjustments
    @ip_address     = opts[:ip_address] # IPv4
    @ip_netmask     = opts[:ip_netmask]
    @ipv6_address   = opts[:ipv6_address]
    @ipv6_prefixlen = opts[:ipv6_prefixlen]

    @blank          = opts[:blank] # Force creation of blank VM (not from an OS template)

    @do_config_disk = opts[:do_config_disk] # Create a cloud-init config disk
    @config_disk_options = opts[:config_disk_options]

    @pool = opts[:pool]
    @pool_obj = Pool.find_by_name(@pool || 'rbd')

    if @pool_obj.nil?
      raise "Pool #{@pool} does not exist!"
    end

    # If no IP is provided, it doesn't make sense to provision from a template;
    # use a blank volume instead
    if @ip_address.nil?
      @blank = true
    end

    # Passwords
    @vnc_password       = opts[:vnc_password]       || %x[/usr/bin/pwgen -nc 8 1].strip
    @conserver_password = opts[:conserver_password] || %x[/usr/bin/pwgen -nc 8 1].strip
    @console_login      = opts[:console_login]      || service.account.login

    # Informational
    @os    = opts[:os]    || 'Generic OS'
    @label = opts[:label] || generate_unique_label(service)

    @vm = service.virtual_machines.create(
      :host => @host,

      :ram         => @ram,
      :storage     => @storage,
      :pool_id     => @pool_obj.id,
      :os_template => @os_template,

      :console_login      => @console_login,
      :conserver_password => @conserver_password,
      :vnc_password       => @vnc_password,

      :os    => @os,
      :label => @label
    )

    account = service.account
    location = @host_obj.location

    unless @blank
      if @ip_address == 'auto'
        # Automatically allocate!
        @ip_address   = account.next_available_ip(:location => location)
        @ipv6_address = account.next_available_ipv6(:location => location)
      end

      # We can infer from what we already know (but opts above always
      # override)
      _auto_ip_gateway, auto_ip_netmask = \
        account.network_settings_for(@ip_address)
      _auto_ipv6_gateway, auto_ipv6_prefixlen = \
        account.network_settings_for(@ipv6_address)

      @vm.virtual_machines_interfaces[0].update_attributes(
        :ip_address => @ip_address,
        :ip_netmask => @ip_netmask || auto_ip_netmask,
        :ipv6_address   => @ipv6_address,
        :ipv6_prefixlen => @ipv6_prefixlen || auto_ipv6_prefixlen)
      @vm.virtual_machines_interfaces[0].save
    end

    # The VM's resource is undefined unless we reload it, not sure why
    @vm = VirtualMachine.find @vm.id

    # Trigger after_save callback which creates the customer DNS records
    @vm.save

    # Define it on the host and create its disk volume
    @vm.define!
    @vm.create_volume!(:blank => @blank)

    if @do_config_disk
      @vm.create_config_disk!(@config_disk_options)

      @vm.update(provisioning_status: 'initializing')
      @vm.create_login_records!(@config_disk_options[:users],
                                @config_disk_options[:arpnet_dk]) if @config_disk_options[:users]

      # After the above final task, the VM must be started for it to
      # auto-provision itself with the config disk
      @vm.change_state!('start')
    end
  end

  def self.generate_unique_label(service, prefix = '')
    login = service.account.login

    5.downto(0) do |i|
      label = prefix + login + "-" + SecureRandom.hex(3).to_s

      unless VirtualMachine.find_by_label(label)
        return label
      end
    end

    raise 'Nothing random found after 5 tries.  We should really, never, ever get here.'
  end

  def self.os_display_name_from_code(cloud_os_struct, code, opts = {})
    @reverse_struct = {}

    cloud_os_struct.each do |_k, v|
      next unless v['series']

      v['series'].each do |version|
        @reverse_struct[version['code']] = {
          title: v['title'],
          version: version['version']
        }
      end
    end

    @ret = ''
    @ret = @reverse_struct[code][:title] if @reverse_struct[code]
    @ret += ' ' + @reverse_struct[code][:version] if opts[:version]

    if @ret.empty?
      return nil
    else
      @ret
    end
  end
end
