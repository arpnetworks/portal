class Login < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :username, presence: true
  validates :password, presence: true

  def self.set_credentials!(vm, username, password, key)
  end

  def self.get_credentials(vm, key)
  end
end
