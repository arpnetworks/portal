class SshHostKey < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :key, presence: true
end
