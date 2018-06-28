@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'hosts.yml')))

$TRUSTED_VM_HOSTS = @config['trusted_vm_hosts']
$TRUSTED_CONSOLE_HOSTS = @config['trusted_console_hosts']
$TRUSTED_MONITOR_HOSTS = @config['trusted_monitor_hosts']
