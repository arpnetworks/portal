class SshHostKey < ActiveRecord::Base
  belongs_to :virtual_machine

  validates :key, presence: true

  before_save :prune_bad_keys
  before_save :generate_fingerprints

  def display_fingerprint_md5
    parts = fingerprint_md5.strip.split(' ')
    label = parts[3]
    label = '' if label == 'comment'
    [parts[1], label].join(' ')
  rescue
    ""
  end

  def display_fingerprint_sha256
    parts = fingerprint_sha256.strip.split(' ')
    label = parts[3]
    label = '' if label == 'comment'
    [parts[1], label].join(' ')
  rescue
    ""
  end

  protected

  def prune_bad_keys
    if key == 'N/A'
      self.key = ""
    end
  end

  def generate_fingerprints
    return if key.blank?

    key_file = Tempfile.new
    key_file.write(key)
    key_file.close

    %w[md5 sha256].each do |fingerprint_hash|
      argv = %W[#{$PROVISIONING['scripts']['ssh_keygen']} -E #{fingerprint_hash} -l -f #{key_file.path}]
      stdout, stderr, status = Open3.capture3(argv.shelljoin)

      if status.exitstatus > 0
        logger.error "Received non-zero exit status when executing: #{argv.join(' ')}"
        logger.error 'stdout: ' + stdout.strip
        logger.error 'stderr: ' + stderr.strip
        logger.error 'status: ' + status.to_s
      else
        send('fingerprint_' + fingerprint_hash + '=', stdout)
      end
    end

    key_file.unlink
  end
end
