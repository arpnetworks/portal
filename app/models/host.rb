class Host < ApplicationRecord
  belongs_to :location

  def display_name
    hostname + " (#{location.code})"
  end

  def self.hosts_for_console_passwd_file
    Host.all.map { |host| host.hostname }.sort
  end

  def self.normalize_host(host)
    @host = host

    unless @host =~ /\.arpnetworks\.com$/
      @host += '.arpnetworks.com'
    end

    @host
  end
end
