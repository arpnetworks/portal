class SshHostKey < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :key, presence: true

  before_save :generate_fingerprints
  before_save :set_key_type

  protected

  def generate_fingerprints
    
  end

  def set_key_type
    begin
      key_type = key.split(' ')

      case key_type[0]
      when 'ssh-rsa'
        self.key_type = 'rsa'
      when 'ssh-dsa'
        self.key_type = 'dsa'
      when 'ssh-ecdsa'
        self.key_type = 'ecdsa'
      when 'ssh-ed25519'
        self.key_type = 'ed25519'
      else
        self.key_type = nil
      end
    rescue StandardError => e
    end
  end
end
