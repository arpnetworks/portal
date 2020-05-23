class SshKey < ActiveRecord::Base
  include ActiveModel::Serializers::JSON

  belongs_to :account

  def attributes
    {
      id: '',
      name: '',
      key: ''
    }
  end
end
