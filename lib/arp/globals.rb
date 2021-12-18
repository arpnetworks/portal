@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'globals.yml')))

if conf = @config[Rails.env]
  # CD-ROM ISOs
  $ISO_BASE = conf['iso_base']

  # To disable online payments
  $PAYMENT_SYSTEM_DISABLED_LOCKFILE = conf['payment_system_disabled_lockfile']

  $ADMINS = conf['admins']['portal']
  $ADMINS_CONSOLE = conf['admins']['console']
  $SUPER_ADMINS = conf['super_admins']
  $IRR_PASSWORD = conf['irr_password']

  $HOST_RANCID      = conf['hosts']['rancid']
  $HOST_RANCID_USER = conf['hosts']['rancid_user']
  $HOST_RANCID_DIR  = conf['hosts']['rancid_dir']
  $HOST_RANCID_PROVISION_VLAN_SCRIPT = conf['hosts']['rancid_provision_vlan_script']
  $HOST_CONSOLE     = conf['hosts']['console']
  $HOST_CACTI       = conf['hosts']['cacti']
  $HOST_CACTI_DIR   = conf['hosts']['cacti_dir']
  $HOST_CACTI_REINDEX_LOCATION_SCRIPT   = conf['hosts']['cacti_scripts']['reindex_location']
  $HOST_CACTI_ADD_GRAPH_FOR_VLAN_SCRIPT = conf['hosts']['cacti_scripts']['add_graph_for_vlan']
  $HOST_CACTI_ADD_CUSTOMER_SCRIPT       = conf['hosts']['cacti_scripts']['add_customer']
  $HOST_CACTI_GET_GRAPH_ID_FOR_VLAN_SCRIPT = conf['hosts']['cacti_scripts']['get_graph_id_for_vlan']
  $HOST_CACTI_DESTROY_VLAN_SCRIPT = conf['hosts']['cacti_scripts']['destroy_vlan']
  $HOST_PORTAL      = conf['hosts']['portal']

  $VLAN_MIN = conf['vlan_min']

  $KEYER    = conf['keyer']

  $SIMPLE_CRYPT_KEY = conf['simple_crypt_key']
  $OTP_PREFIX       = conf['otp_prefix']

  $PORTS_MIN_VNC    = conf['ports']['min']['vnc']
  $PORTS_MIN_WS     = conf['ports']['min']['web_socket']
  $PORTS_MIN_SERIAL = conf['ports']['min']['serial']

  $SLACK_WEBHOOK_URL = conf['slack']['webhook_url']

  $ARIN_API_KEY     = conf['arin']['api_key']

  $PROVISIONING     = conf['provisioning']
  $CLOUD_OS         = $PROVISIONING['cloud_os']
  $CANCEL_SCRIPT    = $PROVISIONING['scripts']['cancel']

  $JOBS_QUEUE_HEALTH_EXCLUSIONS = conf['jobs']['queue_health_exclusions']

  $EXPORT           = conf['export']
  $DNS              = conf['dns']
  $DNS_NOTIFY_CMD   = $DNS['notify_command']

  $STRIPE_API_KEY   = conf['stripe']['api_key']
  $STRIPE_ENDPOINT_SECRET = conf['stripe']['endpoint_secret']
  $STRIPE_PUBLISHABLE_KEY = conf['stripe']['pk_key']

  Stripe.api_key = $STRIPE_API_KEY
end
