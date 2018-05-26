@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'globals.yml')))

# ExceptionNotifier.exception_recipients = %w(gdolley@arpnetworks.com)
# ExceptionNotifier.email_prefix = "[ARP Networks Portal] "
# ExceptionNotifier.sender_address = %("Application Error" <info@arpnetworks.com>)

if conf = @config[Rails.env]
  # CD-ROM ISOs
  $ISO_BASE = conf['iso_base']

  # To disable online payments
  $PAYMENT_SYSTEM_DISABLED_LOCKFILE = conf['payment_system_disabled_lockfile']

  $ADMINS = conf['admins']
  $IRR_PASSWORD = conf['irr_password']

  $HOST_RANCID      = conf['hosts']['rancid']
  $HOST_RANCID_USER = conf['hosts']['rancid_user']
end
