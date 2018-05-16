module Tender
  @config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'tender.yml')))

  if conf = @config[ENV['RAILS_ENV']]
    TENDER_SECRET = conf['secret']
    TENDER_HOST   = conf['host']
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      include InstanceMethods
    end
  end

  module ClassMethods
    def tender_token_expiry_timestamp
      1.year.from_now.to_i
    end
  end

  module InstanceMethods
    def tender_token(expiry)
      method = OpenSSL::Digest.new("SHA1")
      string = "#{TENDER_HOST}/#{email}/#{expiry}"
      OpenSSL::HMAC.hexdigest(method, TENDER_SECRET, string)
    end
  end
end
