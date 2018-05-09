module PasswordEncryption
  @config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'password_encryption.yml')))
  SALT = @config[ENV['RAILS_ENV']]['salt']

  def self.included(base)
    base.extend(ClassMethods)
    base.module_eval do
      include InstanceMethods

      attr_accessor :password_encrypted

      validates_presence_of     :password
      validates_confirmation_of :password, :if => Proc.new { |account| !account.password_encrypted }
    end
  end

  module ClassMethods
    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  end

  module InstanceMethods
    def before_save
      # If password_confirmation wasn't specified, then we can assume the 
      # password was not meant to be changed, so we don't want to rehash it, 
      # since we already have the hashed version.  However, all new records 
      # need password encryption regardless.
      if (!password_confirmation.nil? and password_confirmation != '') or new_record?
        self.password = self.class.encrypt(password, SALT)
        self.password_encrypted = true
      end
    end

    def authenticated?(pass)
      password == self.class.encrypt(pass, SALT)
    end
  end
end
