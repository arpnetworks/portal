def rebuild_vps_passwd_on_console_server!(host)
  host = host.sub(/\.arpnetworks\.com$/, '')
  puts "Rebuilding VPS passwd file on console server for host: #{host}"
  build_and_reload_conserver(host)
end

def configure_vlan!(vlan, ipv4_block, ipv6_block, descr, location)
  h = `hostname`.chomp

  exec = "cd #{$HOST_RANCID_DIR} && #{$HOST_RANCID_PROVISION_VLAN_SCRIPT} #{ipv4_block} #{ipv6_block} #{vlan} \"#{descr}\" #{location}"
  puts "Executing the following:"
  puts exec
  puts ""

  if h == $HOST_PORTAL
    Kernel.system("ssh -t -A #{$HOST_RANCID}.arpnetworks.com <<EOF
#{exec}
EOF")
  end
end

def configure_cacti!(vlan, username, password, location)
  h = `hostname`.chomp

  exec = "ssh #{$HOST_CACTI} 'cd #{$HOST_CACTI_DIR} && #{$HOST_CACTI_REINDEX_LOCATION_SCRIPT} #{location} && #{$HOST_CACTI_ADD_GRAPH_FOR_VLAN_SCRIPT} #{vlan} #{location} && #{$HOST_CACTI_ADD_CUSTOMER_SCRIPT} #{username} #{password} #{vlan} #{location}'"
  puts "Executing the following:"
  puts exec
  puts ""

  if h == $HOST_PORTAL
    Kernel.system(exec)
  end
end

def local_graph_id_for_vlan(vlan, location)
  %x(ssh #{$HOST_CACTI} 'cd #{$HOST_CACTI_DIR} && #{$HOST_CACTI_GET_GRAPH_ID_FOR_VLAN_SCRIPT} #{vlan} #{location}').chomp
end

# Code similar to this is in:
# controllers/admin/vlans_controller.rb
def shutdown_vlan(otp, vlan_id, location)
  h = `hostname`.chomp

  cmd = 'shutdown_vlan'
  exec = "ssh -o 'ConnectTimeout 5' #{$HOST_RANCID_USER}@#{$HOST_RANCID} '#{otp}' '#{cmd}' '#{vlan_id}' '#{location}'"

  if h == $HOST_PORTAL
    Kernel.system(exec)
  end
end

def yesno(s)
  print s + " [y/N] : "

  yn = STDIN.gets.chomp

  yn.downcase == 'y'
end

def continue?
  yesno("Continue?")
end

