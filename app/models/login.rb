class Login < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :username, presence: true
  validates :password, presence: true

  def self.set_credentials!(vm, username, password, key)
    return unless vm

    cipher = OpenSSL::Cipher::AES256.new :CBC
    cipher.encrypt

    begin
      cipher.key = key
      iv = cipher.random_iv

      encrypted_password = cipher.update(password) + cipher.final

      vm.logins.create({
                         username: username,
                         password: Base64.encode64(encrypted_password),
                         iv: Base64.encode64(iv)
                       })
    rescue StandardError
    end
  end

  def self.get_credentials(vm, key)
    return [] unless vm

    logins = vm.logins

    logins.each do |login|
      decipher = OpenSSL::Cipher::AES256.new :CBC
      decipher.decrypt

      begin
        decipher.iv = Base64.decode64(login.iv)
        decipher.key = key
        login.password = decipher.update(Base64.decode64(login.password)) + decipher.final
      rescue StandardError
        login.password = ''
      end
    end
  end
end
