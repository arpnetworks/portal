class Account < ActiveRecord::Base
  include PasswordEncryption
  include Tender
  include BillingSystemModels::CreditCards
  include BillingSystemModels::Invoices

  has_many :services
  has_many :ssh_keys
  has_many :jobs

  validates_presence_of      :login
  validates_presence_of      :email
  validates_uniqueness_of    :login
  validates_uniqueness_of    :email
  validates_format_of        :email   , :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_length_of        :password, :minimum => 8
  validates_length_of        :login   , :within => 3..48
  validates_presence_of      :password_confirmation, :if => :password_changed?
  validates_format_of        :login   , :with => /\A[0-9a-z_-]+\z/i, :message => 'can contain only numbers and letters.'
  validates_format_of        :email_billing, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\s*\Z/i, :allow_blank => true
  validates_format_of        :email2       , :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\s*\Z/i, :allow_blank => true

  scope :suspended, -> { where("vlan_shutdown = 1") }

  def validate
  end

  def display_name
    if company && !company.empty?
      return company
    end

    if first_name && !first_name.empty?
      return first_name
    end

    login
  end

  # Like display_name() but more for the backend admin
  def display_account_name
    if company && !company.empty?
      return company
    end

    if first_name && !first_name.empty?
      return "#{first_name} #{last_name}"
    end

    login
  end

  def display_account_name_with_login
    display_account_name + " (" + login + ")"
  end

  def gravatar_url(options = {:size => 60 })
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest((email||'').downcase)}?s=#{options[:size]}"
  end

  def arp_admin?
    $ADMINS.include?(login)
  end

  def arp_sub_admin?
    false # Not used right now
  end

  # An account that has its VLAN in 'shutdown' state is suspended
  def suspended?
    vlan_shutdown
  end

  def suspended_at
    vlan_shutdown_at
  end

  def suspend!
    if !suspended?
      self.vlan_shutdown = true
      self.vlan_shutdown_at = Time.now
      save
    end
  end

  def unsuspend!
    if suspended?
      self.vlan_shutdown = false
      self.vlan_shutdown_at = nil
      save
    end
  end

  # Return the active IP_BLOCK service record associated with this account
  def ip_block
    service_code = ServiceCode.find_by_name('IP_BLOCK')

    if service_code
      services.active.find_by_service_code_id(service_code.id)
    end
  end

  # Returns all active IpBlock records associated with this account,
  # regardless of service code
  def ip_blocks(opts = {})
    location = opts[:location]

    ip_blocks = []
    services.active.each do |service|
      if location
        ip_blocks_in_location = \
          service.ip_blocks.select do |ip_block|
            ip_block.location == location
          end

        if !ip_blocks_in_location.empty?
          ip_blocks << ip_blocks_in_location
        end
      else
        if !service.ip_blocks.empty?
          ip_blocks << service.ip_blocks
        end
      end
    end
    ip_blocks.flatten
  end

  # Utility method used during automatic provisioning
  #
  # Returns the gateway and netmask this for this account, given the
  # specified IP. Can be scoped by location, or any other option supported by
  # #ip_blocks above
  def network_settings_for(ip, opts = {})
    return nil unless ip

    begin
      cidr_obj = NetAddr::CIDR.create(ip)
    rescue NetAddr::ValidationError
      return nil
    end

    ip_blocks(opts).each do |ip_block|
      if ip_block.version == cidr_obj.version
        if ip_block.contains?(ip)
          if ip_block.version == 6
            v6_prefixlen = ip_block.routed? ? 48 : 64

            return [ip_block.gateway, v6_prefixlen]
          else
            return [ip_block.gateway, ip_block.netmask]
          end
        end
      end
    end

    nil
  end

  def vlan(opts = {})
    # We will assume the VLAN of first IP block is account VLAN
    # (given optional location)
    blocks = ip_blocks(opts)
    first  = blocks.first
    if first
      first.vlan
    end
  end

  # Returns all active BandwidthQuota records associated with this account,
  # regardless of service code
  def bandwidth_quotas
    bandwidth_quotas = []
    services.active.each do |service|
      if !service.bandwidth_quotas.empty?
        bandwidth_quotas << service.bandwidth_quotas
      end
    end
    bandwidth_quotas.flatten
  end

  # Returns all active VirtualMachine records associated with this account,
  # regardless of service code.  Can be scoped by location.
  def virtual_machines(opts = {})
    location = opts[:location]

    virtual_machines = []
    services.active.each do |service|
      if location
        virtual_machines_in_location = \
          service.virtual_machines.select do |virtual_machine|
            virtual_machine.location == location
          end

        if !virtual_machines_in_location.empty?
          virtual_machines << virtual_machines_in_location
        end
      else
        if !service.virtual_machines.empty?
          virtual_machines << service.virtual_machines
        end
      end
    end

    virtual_machines.flatten
  end

  # Returns IPs we've recorded as assigned to the interfaces belonging to VMs
  # across all VMs on this account.  Can be scoped by location.
  #
  # Note: only applies to IPv4
  def ips_in_use(opts = {})
    interfaces = \
      virtual_machines(opts).map do |virtual_machine|
        virtual_machine.virtual_machines_interfaces
      end.flatten

    interfaces.map do |interface|
      interface.ip_address
    end
  end

  def ips_available(opts = {})
    v4_blocks = ip_blocks(opts).select do |ip_block|
      ip_block.version == 4
    end

    all_usable_ips = v4_blocks.map do |ip_block|
      ip_block.ip_range_usable_as_array
    end.flatten

    all_usable_ips - ips_in_use(opts)
  end

  def next_available_ip(opts = {})
    ips_available(opts).first
  end

  # We generate a random IPv6 address within the account's subnet and
  # just assume it isn't used
  def next_available_ipv6(opts = {})
    v6_blocks = ip_blocks(opts).select do |ip_block|
      ip_block.version == 6
    end

    # Assume only 1 IPv6 block exists per account per location
    v6_block = v6_blocks.first

    return nil unless v6_block

    hex = [SecureRandom.hex(2)[0..3], SecureRandom.hex(2)[0..3]]

    v6_block.cidr_obj.ip(:Short => true) + hex.join(':')
  end

  # Returns an array of strings representing the reverse DNS zones in
  # which this account may create records
  def reverse_dns_zones
    ip_blocks_sorted = ip_blocks.sort do |a, b|
      a.version <=> b.version # IPv4 to appear before IPv6
    end

    ip_blocks_sorted.map do |ip_block|
      ip_block.cidr_obj.arpa.chomp('.')
    end
  end

  # Returns true or false, depending on whether or not this account owns the
  # DnsRecord model passed as the first argument
  #
  # For IPv4 PTR records, the account may not own the network number, first
  # IP (gateway), or broadcast address
  def owns_dns_record?(dns_record)
    result = false

    # Handle IPv6 prefix match
    if dns_record.name =~ /\.ip6\.arpa$/
      reverse_dns_zones.each do |zone|
        if zone =~ /\.ip6\.arpa$/
          if dns_record.name =~ /#{zone}$/
            return true
          end
        end
      end
    end

    # Handle RFC 2317 style records
    if dns_record.name =~ /^([0-9]+)-([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\.in-addr\.arpa$/
      if dns_record.type == 'NS'
        lower_ip = "#{$5}.#{$4}.#{$3}.#{$1}" # omg it's Perl!!
        upper_ip = "#{$5}.#{$4}.#{$3}.#{$2}"

        ip_blocks.each do |ip_block|
          ip_block = ip_block.cidr_obj
          if ip_block.version == 4 &&
             ip_block.network == lower_ip &&
             ip_block.last    == upper_ip &&
             ip_block.contains?(lower_ip) && 
             ip_block.contains?(upper_ip)
               result = true
          end
        end
      end

      return result
    end

    ip = dns_record.ip

    if !ip
      return false
    end

    ip_obj = NetAddr::CIDR.create(ip)

    ip_blocks.each do |ip_block|
      ip_block = ip_block.cidr_obj
      if ip_block.version == ip_obj.version
        if ip_block.contains?(ip)
          if dns_record.type != 'PTR'
            result = true
          else
            if ip_block.version == 4
              if ip_block.network != ip &&
                 ip_block.nth(1)  != ip &&
                 ip_block.last    != ip
                result = true
              end
            else
              result = true
            end
          end
        end
      end
    end

    result
  end

  ##################
  # BEGIN: Finders #
  ##################

  def find_virtual_machine_by_id(id)
    services.map { |s| s.virtual_machines.find_by_id(id) }.compact[0]
  end

  def find_backup_quota_by_id(id)
    services.map { |s| s.backup_quotas.find_by_id(id) }.compact[0]
  end

  ##################
  # END: Finders   #
  ##################

  def email_for_sales_receipts
    (email_billing && !email_billing.empty?) ? email_billing : email
  end

  # For SalesReceipt
  def sold_to
    s =  "#{first_name} #{last_name}\n"
    s += "#{company}\n" if company && !company.empty?
    s += "#{address1}\n"
    s += "#{address2}\n" if address2 && !address2.empty?
    s += "#{city}, #{state} #{zip}\n"
    s += "#{country}"

    s
  end

  alias :bill_to :sold_to

  def mrc(opts = {})
    conditions = 'billing_interval = 1 and billing_amount > 0'

    monthly_active_services = services.active.where(conditions)

    mrc = monthly_active_services.inject(0) do |sum, x|
      if x.deleted_at.nil?
      sum + x.billing_amount
      end
    end

    if opts[:formatted]
      money(mrc)
    else
      mrc
    end
  end

  def current?
    return true if invoices_unpaid.size == 0

    total_outstanding = invoices_unpaid.inject(0) do |sum, invoice|
      sum + invoice.balance.to_f
    end

    # Hard coded for now
    total_outstanding < 50
  end

  # A customer is active if they have active services in their account
  def active?
    !services.active.empty?
  end

  def old_customer?
    !services.empty? && !active?
  end

  def customer_since
    return nil if services.empty?

    first_service = services.sort { |a,b| a.created_at <=> b.created_at }.first
    first_service.created_at
  end

  def cancellation_date
    return nil if services.empty?
    return nil if active?

    last_service = services.where("deleted_at is not null").sort { |a,b| a.deleted_at <=> b.deleted_at }.last
    last_service.deleted_at
  end

  def create_pro_rated_invoice!(code, descr, amount, opts = {})
    if amount <= 0
      return nil
    end

    @invoice = invoices.create(
      :pending => opts[:pending],
      :terms   => 'Due upon receipt',
      :message => 'Thank you for your business'
    )
    @invoice.line_items.create(
      :code        => code,
      :description => descr + " (pro-rated)",
      :amount      => amount
    )

    @invoice
  end

  # This method was ripped from charging.rb and is temporary until we build
  # payment functionality into the Portal (a way for customers to pay their
  # invoices online, without our intervention)
  def charge_unpaid_invoices!(report_only = true, show_sr = false, email_dn = false, suspend_mode = false)
    unpaid = invoices.unpaid

    unpaid = unpaid.select { |invoice| invoice.paid == 0 } # No partial invoices

    account_string = "#{display_account_name} (#{id})"

    invoice_string = unpaid.size > 1 ? "invoices" : "invoice"

    puts "#{account_string} has #{unpaid.size} unpaid #{invoice_string}" +
         (suspended? ? " and is SUSPENDED (since " + suspended_at.localtime.to_s + ")" : "")

    if report_only && credit_card.nil?
      puts "#{account_string} has no credit card, probably canceled..."
    end

    amount_to_charge = 0
    unpaid.each do |unpaid_invoice|
      puts "   Invoice #{unpaid_invoice.id}: Total #{money(unpaid_invoice.total)}"
      amount_to_charge += unpaid_invoice.total
    end

    puts "      Line Items:"
    line_items = sales_receipt_line_items(unpaid)

    line_items.each do |line_item|
      puts "        #{line_item[:description]}, #{money(line_item[:amount])}"
    end

    amount_charged = 0

    if !report_only
      puts ""

      cc = credit_card
      if cc.nil?
        puts "This account #{account_string} does not have a credit card, skipping..."
        puts ""
      elsif cc.number == '41111'
        puts "This account #{account_string} has a disabled credit card, skipping..."
        puts ""
      else
        unless line_items.empty?
          puts "Attempting to charge #{account_string} for #{money(amount_to_charge)}... "

          begin
            success = false
            ActiveRecord::Base.transaction do
              charge_rec, sr = cc.charge_with_sales_receipt(amount_to_charge,
                                                            line_items,
                                                            :email_decline_notice => email_dn,
                                                            :email_sales_receipt => true)
              if charge_rec
                puts "Success!"
                puts ""

                success = true
                amount_charged = amount_to_charge

                unpaid.each do |invoice|
                  invoice.paid = true
                  invoice.save

                  # Don't ask me why we have to re-find it.  Using charge_rec directly will
                  # cause: "instance of IO needed" to be thrown from YAML::load
                  charge = Charge.find(charge_rec.id)
                  transaction_id = YAML::load(charge.gateway_response).params["transaction_id"]

                  invoice.payments.create({
                    :account_id => invoice.account.id,
                    :date => Time.now,
                    :reference_number => transaction_id,
                    :method => 'Credit Card',
                    :amount => invoice.total
                  })
                end
              else
                print "FAILED!  "

                if email_dn
                  puts "Decline notice emailed to #{email}"
                else
                  puts "Silently ignoring..."
                end

                puts ""
              end
            end

          rescue Exception => e
            puts ""
            puts "Received exception: #{e}"
            puts "#{e.backtrace.to_yaml}"
            puts "Continuing..."
          end
        end
      end
    else
      if show_sr
        sr = SalesReceipt.new(:account_id => id,
                              :date => Time.now,
                              :sold_to => sold_to)
        sr.line_items.build(line_items)

        tmail = BillingSystemModels::Mailer.sales_receipt(sr)

        puts ""
        puts tmail.body
        puts ""
      end

      if suspend_mode
        puts ""

        if suspended?
          puts "Account already suspended, skipping..."
        else
          if vlan
            puts "Enter <location> and OTP to suspend account, empty string to disregard:"

            thy_command = STDIN.gets.chomp

            if thy_command
              if thy_command.empty?
                puts "As you wish, skipping..."
              else
                puts "Dropping the hammer!"

                location, otp = thy_command.split(' ')

                if location.nil? || otp.nil?
                  puts "I need *location* _and_ the OTP"
                else
                  shutdown_vlan(otp, vlan, location)
                  suspend!
                end
              end
            end
          else
            puts "In suspend mode, but could not find account VLAN, skipping..."
          end
        end
      end

      puts ""
    end

    [amount_to_charge, amount_charged]
  end

  # Also ripped from charging.rb
  def sales_receipt_line_items(invoices)
    line_items = []

    invoices = invoices.sort { |a, b| a.date <=> b.date }

    invoices.each do |invoice|
      invoice.line_items.order(date: :desc)
      invoice.line_items.each do |line_item|
        date = line_item.date.strftime("%m-%d-%Y")
        line_items << {
          :code => line_item.code,
          :description => date + ": " + line_item.description,
          :amount => line_item.amount.to_f
        }
      end
    end

    line_items
  end

  class <<self

    # Authenticates a user by their login name and unencrypted password.
    # Returns the user or nil.
    def authenticate(login, password)
      u = find_by(login: login, active: true)
      u && u.authenticated?(password) ? u : nil
    end
  end
end
