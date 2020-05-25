class SshKey < ActiveRecord::Base
  include ActiveModel::Serializers::JSON

  belongs_to :account

  validates :name, presence: true
  validates :key, presence: true
  validates :username, presence: true

  before_validation :ensure_username

  def attributes
    {
      id: '',
      name: '',
      key: '',
      username: ''
    }
  end

  protected

  def ensure_username
    if username.blank?
      self.username = account.login
    end
  end
end
