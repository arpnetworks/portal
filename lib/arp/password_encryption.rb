module PasswordEncryption
  @config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'password_encryption.yml')))

  if conf = @config[Rails.env]
    SALT = conf['salt']
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      include InstanceMethods
    end
  end

  module ClassMethods
    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  end

  module InstanceMethods
    def authenticated_under_legacy_system?(pass)
      legacy_encrypted_password == self.class.encrypt(pass, SALT)
    end
  end
end
