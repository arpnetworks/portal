module Zammad
  @config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'zammad.yml')))

  if conf = @config[ENV['RAILS_ENV']]
    ZAMMAD_SECRET = conf['secret']
    ZAMMAD_HOST   = conf['host']
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      include InstanceMethods
    end
  end

  module ClassMethods
    def zammad_token_expiry_timestamp
      5.minutes.from_now.to_i
    end
  end

  module InstanceMethods
    def zammad_token(expiry)
      # Base64 encode names once
      encoded_first_name = Base64.strict_encode64(first_name.to_s)
      encoded_last_name = Base64.strict_encode64(last_name.to_s)

      method = OpenSSL::Digest.new('SHA256')
      string = Zammad.digest_string(
        ZAMMAD_HOST,
        email,
        expiry,
        encoded_first_name,  # Use encoded version
        encoded_last_name    # Use encoded version
      )
      OpenSSL::HMAC.hexdigest(method, ZAMMAD_SECRET, string)
    end

    def zammad_sso_url
      return '' if ZAMMAD_HOST.blank?

      url = if ZAMMAD_HOST == 'localhost'
              "http://#{ZAMMAD_HOST}:3000"
            else
              "https://#{ZAMMAD_HOST}"
            end

      expiry = Account.zammad_token_expiry_timestamp
      url_encoded_email = CGI.escape(email)

      # Use the same encoded values as in token generation
      encoded_first_name = Base64.strict_encode64(first_name.to_s)
      encoded_last_name = Base64.strict_encode64(last_name.to_s)

      "#{url}/auth/sso?email=#{url_encoded_email}&expires=#{expiry}&fn=#{encoded_first_name}&ln=#{encoded_last_name}&token=#{zammad_token(expiry)}"
    end
  end

  def self.digest_string(host, email, expiry, first_name, last_name)
    parts = [
      host,
      email,
      expiry.to_s,
      first_name,   # Already encoded
      last_name     # Already encoded
    ]
    parts.join('|')
  end
end
