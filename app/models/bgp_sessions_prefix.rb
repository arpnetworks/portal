class BgpSessionsPrefix < ActiveRecord::Base
  belongs_to :bgp_session

  before_save   :set_prefixlen_mix_man
  after_create  :mail_irr_route_object_add
  after_destroy :mail_irr_route_object_remove

  def version
    case prefix
    when /\./
      4
    when /:/
      6
    end
  end

  def origin_asn
    bgp_session.asn
  end

  def origin
    'AS' + origin_asn.to_s
  end

  def set_prefixlen_mix_man
    cidr = NetAddr::CIDR.create(prefix)
    self.prefixlen = cidr.bits

    if prefixlen_min.nil?
      self.prefixlen_min = prefixlen
    end

    if prefixlen_max.nil?
      self.prefixlen_max = (version == 6) ? 48 : 24
    end

    case version
    when 4
      if prefixlen_max > 24
        self.prefixlen_max = 24
      end

    when 6
      if prefixlen_max > 48
        self.prefixlen_max = 48
      end
    end

    if prefixlen_min < prefixlen
      self.prefixlen_min = prefixlen
    end
  end

  def mail_irr_route_object_add
    # Create IRR record
    Mailer.irr_route_object('ADD', self).deliver_now
  end

  def mail_irr_route_object_remove
    # Remove IRR record
    Mailer.irr_route_object('REMOVE', self).deliver_now
  end

  protected

  def validate
    begin
      unless prefix =~ /\/.+$/
        raise 'Requires a slash and prefix length'
      end

      NetAddr::CIDR.create(prefix)

      # No exception?  Carry on...
    rescue Exception
      errors.add(:prefix, "has bad format. Must be 'IP/Prefix-Length'")
    end
  end
end
