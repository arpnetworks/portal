class SshHostKey < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :key, presence: true

  before_save :generate_fingerprints

  protected

  def generate_fingerprints
    return if key.blank?

    key_file = Tempfile.new
    key_file.write(key)
    key_file.close

    %w[md5 sha256].each do |fingerprint_hash|
      argv = %W{/usr/bin/ssh-keygen -E #{fingerprint_hash} -l -f #{key_file.path}}
      stdout, stderr, status = Open3.capture3(argv.shelljoin)
      self.send('fingerprint_' + fingerprint_hash + '=', stdout)
    end

    key_file.unlink
  end
end
