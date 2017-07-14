# Dependencies
# ------------

require 'rubygems'

begin
  require 'active_record'
rescue LoadError
  require 'activerecord'
end

gem 'netaddr'

# Our models
# ----------

$:.unshift File.join(File.dirname(__FILE__), "lib", "models")

require 'dns_domain'
require 'dns_record'
