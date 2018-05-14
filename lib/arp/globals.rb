@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'globals.yml')))

# ExceptionNotifier.exception_recipients = %w(gdolley@arpnetworks.com)
# ExceptionNotifier.email_prefix = "[ARP Networks Portal] "
# ExceptionNotifier.sender_address = %("Application Error" <info@arpnetworks.com>)

# CD-ROM ISOs
$ISO_BASE = @config[ENV['RAILS_ENV']]['iso_base']

# To disable online payments
$PAYMENT_SYSTEM_DISABLED_LOCKFILE = @config[ENV['RAILS_ENV']]['payment_system_disabled_lockfile']

# Retrieve IRR password
$IRR_PASSWORD = File.read(File.join(File.dirname(__FILE__), 'irr.txt')) rescue ''
$IRR_PASSWORD = $IRR_PASSWORD.strip
