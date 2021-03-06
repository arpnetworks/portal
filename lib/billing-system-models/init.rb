# Dependencies
# ------------

require 'rubygems'

begin
  require 'active_record'
rescue LoadError
  require 'activerecord'
end

gem 'actionmailer'
gem 'activemerchant'

require 'tmpdir'

$:.unshift File.join(File.dirname(__FILE__), "lib")

# Gateway configuration
# ---------------------

require 'gateway'

# GPG configuration
# -----------------

require 'gpg'

# Our mixins
# ----------

require 'credit_cards'
require 'invoices'
require 'sellable'

# Our models
# ----------

$:.unshift File.join(File.dirname(__FILE__), "lib", "models")

require 'charge'
require 'credit_card'
require 'invoice'
require 'payment'
require 'sales_receipt'

require 'sales_receipts_line_item'
require 'invoices_line_item'
require 'invoices_payment'

# For email notifications
require 'mailer'
