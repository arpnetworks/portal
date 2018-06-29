class Host < ActiveRecord::Base
  belongs_to :location

  def display_name
    hostname + " (#{location.code})"
  end

  def self.hosts_for_console_passwd_file
    Host.all.map { |host| host.hostname }.sort
  end
end
