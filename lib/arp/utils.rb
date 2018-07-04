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

