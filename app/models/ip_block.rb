class IpBlock < ActiveRecord::Base
  include Resourceable
  include Textilizable

  belongs_to :parent_block, :class_name => 'IpBlock', :foreign_key => 'ip_block_id'
  belongs_to :location

  validates_presence_of :cidr
  validate :proper_parent_block

  textilizable :notes

  scope :superblocks, -> { where("ip_block_id IS NULL").order('seq, network') }

  def cidr_obj
    @cidr_obj ||= NetAddr::CIDR.create(cidr)
  end

  # Return the first IP
  def ip_first
    NetAddr::CIDR.create(cidr_obj.to_i(:network) + 2).ip
  end

  def ip_range_usable
    return unless cidr

    if cidr_obj.version == 6
      return 'All except gateway (::1)'
    end

    first = ip_first
    last  = NetAddr::CIDR.create(cidr_obj.broadcast(:Objectify => true).to_i(:ip) - 1).ip

    if first == last
      first
    else
      "#{first} - #{last}"
    end
  end

  # Only for IPv4
  def ip_range_usable_as_array
    return unless cidr

    if cidr_obj.version == 6
      raise ArgumentError.new("This method is only for IPv4")
    end

    # Chop off the first 2 (subnet number, gateway) and last (broadcast) IP
    cidr_obj.enumerate[2..-2]
  end

  def gateway(opts = {})
    NetAddr::CIDR.create(cidr_obj.to_i(:ip) + 1).ip({ :Short => true }.merge(opts)) if cidr
  end

  def netmask
    cidr_obj.version == 4 ? cidr_obj.wildcard_mask : 'N/A' if cidr
  end

  def broadcast(opts = {})
    cidr_obj.version == 4 ? cidr_obj.broadcast(opts) : 'N/A' if cidr
  end

  def subnets(includes = {})
    # All blocks who have me as a parent
    IpBlock.includes(includes).where(["ip_block_id = ?", id]).order('seq, network')
  end

  def subnets_available(prefixlen, opts = {})
    if opts[:limit].to_i > 0
      limit = opts[:limit].to_i - 1
    else
      limit = -1 # No limit
    end
    opts.delete(:limit)

    @allocator = IPAllocator.new(cidr_obj, subnets.map { |o| o.cidr_obj })
    @available = @allocator.available(prefixlen, opts)[0..limit].map do |cidr_obj|
      IpBlock.new(:cidr => cidr_obj.to_s(:Short => true))
    end
  rescue ArgumentError, NetAddr::BoundaryError
    []
  end

  def account_name
    account && account.display_account_name
  end

  def short_desc
    "#{cidr}: #{account_name} #{label}"
  end

  def arin_network_name
    network_name     = "ARPNET"
    network_name     = network_name + (cidr_obj.version == 6 ? '6' : '') + '-'
    cidr_with_dashes = cidr.to_s.gsub(/[\.:+\/]/, '-')
    cidr_with_dashes_shorter = cidr_with_dashes.gsub(/--*/, '-')
    "#{network_name}#{cidr_with_dashes_shorter}".upcase
  end

  def origin_as
    # Cannot modify yet
    '25795'
  end

  def version
    cidr_obj.version
  end

  # Returns a string of entries suitable for a BIND zone file delegating this
  # IP block to the name server(s) supplied as arguments
  #
  # IPv4 reverse delegation style is RFC 2317
  #
  # Only IPv4 blocks smaller than /24 are supported
  # Only IPv6 blocks of size /48 are supported (which is the only size we hand
  # out)
  def reverse_dns_delegation_entries(name_servers, opts = {})
    # Validation
    if version == 4 && cidr_obj.bits <= 24
      return "Not supported: address block too larger (/24 or larger)"
    end

    if version == 6 && cidr_obj.bits != 48
      return "Not supported: address block not equal to /48"
    end

    name_servers = [name_servers].flatten # Make into array

    entry = ''

    if version == 6
      third_part = cidr_obj.to_s(:Short => true).\
                            sub(/^([0-9a-f]+:){2}(.*)::\/48$/i, '\2')
      record = third_part.reverse.gsub(/(.)/, '\1.').chop

      name_servers.each do |name_server|
        entry += "#{record}    IN  NS  #{name_server}.\n"
      end
    end

    if version == 4
      first = cidr_obj.first.sub(/^[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)/, '\1')
      last  = cidr_obj.last.sub(/^[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)/, '\1')

      entry =  "; BEGIN: RFC 2317 sub-Class C delegation\n"
      entry += ";\n"

      first_time_in_loop = true
      name_servers.each do |name_server|
        if first_time_in_loop
          entry += "#{first}-#{last}\t\tIN\tNS\t#{name_server}.\n"
        else
          entry += "\t\tIN\tNS\t#{name_server}.\n"
        end

        first_time_in_loop = false
      end

      entry += ";\n"

      begin_at = first.to_i + 2
      end_at   = last.to_i - 1

      (begin_at..end_at).each do |ip|
        entry += "#{ip}\t\tIN\tCNAME\t#{ip}.#{rfc2317_zone_name}.\n"
      end

      entry += ";\n"
      entry += "; END\n"
    end

    entry
  end

  def rfc2317_zone_name
    if version == 6
      return "Not applicable to IPv6"
    end

    if version == 4
      first = cidr_obj.first.sub(/^[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)/, '\1')
      last  = cidr_obj.last.sub(/^[0-9]+\.[0-9]+\.[0-9]+\.([0-9]+)/, '\1')

      arpa_zone = cidr_obj.last.sub(/^([0-9]+)\.([0-9]+)\.([0-9]+)\.[0-9]+/,
                                    '\3.\2.\1.in-addr.arpa')

      "#{first}-#{last}.#{arpa_zone}"
    end
  end

  def reverse_dns_zone_name
    case version
    when 4
      zone_name = cidr_obj.arpa.chomp('.')
    when 6
      cidr_with_32_prefix = cidr_obj.resize(32)
      if cidr_with_32_prefix.network(:Short => true) == "2607:f2f8::"
        return cidr_with_32_prefix.arpa.chomp('.')
      end
      cidr_with_29_prefix = cidr_obj.resize(29)
      if cidr_with_29_prefix.network(:Short => true) == "2a07:12c0::"
        return cidr_with_29_prefix.arpa.chomp('.')
      end
    end
  end

  # Returns the next available subnet for allocation of size prefixlen.
  def self.available_for_allocation(prefixlen, location_code, opts = {})
    if prefixlen > 32
      return "Not applicable to IPv6"
    end

    if prefixlen > 30
      return "Only /30 and larger blocks are supported"
    end

    location = Location.find_by_code(location_code)

    if !location
      return "Location not found"
    end

    where("available is true and cidr like '%/#{prefixlen}'").order('id').each do |ip_block|
      if ip_block.location == location
        return ip_block
      end
    end

    nil
  end

  def mail_to(text, display_text, html_options)
    text
  end

  def contains?(ip)
    cidr_obj.contains?(ip)
  end

  def location
    if location_id
      return Location.find(location_id)
    else
      if parent_block
        parent_block.location
      else
        nil
      end
    end
  end

  def self.account(ip)
    return nil unless ip

    begin
      cidr_obj = NetAddr::CIDR.create(ip)
    rescue NetAddr::ValidationError
      return nil
    end

    case cidr_obj.version
    when 4
      lhs = cidr_obj.ip.sub(/\.\d+$/, '.')
    when 6
      lhs = cidr_obj.ip(:Short => true).sub(/::\d+$/, ':')
    else
      raise ArgumentError
    end

    possible_parents = IpBlock.where("cidr like '#{lhs}%' and vlan >= #{$VLAN_MIN}")

    @parent_net = nil
    possible_parents.each do |ip_block|
      if ip_block.contains?(ip)
        @parent_net = ip_block
      end
    end

    @parent_net.account if @parent_net
  end

  protected

  before_save do
    self.network = cidr_obj.to_i(:network)
    @cidr_obj = nil # Flush memoization
  end

  def proper_parent_block
    if parent_block
      unless NetAddr::CIDR.create(parent_block.cidr).contains?(cidr)
        errors.add(:parent_block, "does not contain (is a supernet of) #{cidr}")
      end
    end
  end
end
