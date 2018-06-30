def rebuild_vps_passwd_on_console_server!(host)
  host = host.sub(/\.arpnetworks\.com$/, '')
  puts "Rebuilding VPS passwd file on console server for host: #{host}"
  build_and_reload_conserver(host)
end

def yesno(s)
  print s + " [y/N] : "

  yn = STDIN.gets.chomp

  yn.downcase == 'y'
end

def continue?
  yesno("Continue?")
end

