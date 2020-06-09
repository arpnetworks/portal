class SshHostKey < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :key, presence: true

  before_save :generate_fingerprints

  protected

  def generate_fingerprints
    return if key.blank?


  end
end
