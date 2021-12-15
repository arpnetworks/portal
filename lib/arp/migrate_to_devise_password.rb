module MigrateToDevisePassword
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
    def migrate_to_devise_password!(params)
      return if params.nil?

      legacy_authenticate(params) do |account|
        account.update_devise_password!(params[:password])
      end
    end

    def legacy_authenticate(params)
      account = Account.find_by(login: params[:login], active: true)
      return if account.nil?

      if account.legacy_encrypted_password == encrypt(params[:password], SALT)
        yield account
      end
    end

    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end
  end

  module InstanceMethods
    def update_devise_password!(new_password)
      return if new_password.blank?
      return if encrypted_password.present?

      self.password = new_password
      self.password_confirmation = new_password
      save!
    end
  end
end
