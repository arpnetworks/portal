require 'billing-system-models/init.rb'

@config = YAML.load(File.read(File.join(File.dirname(__FILE__), '..', '..', 'config', 'arp', 'globals.yml')))

if conf = @config[ENV['RAILS_ENV']]
  BillingSystemModels::Mailer.sales_receipt_headers = {
    :subject => "Sales Receipt (#{Time.new.strftime("%b. %Y")}); " + conf['sr_subject'],
    :from    => "billing@arpnetworks.com",
  }

  BillingSystemModels::Mailer.decline_notice_headers = {
    :subject => "Updated Credit Card Information Required",
    :from    => "billing@arpnetworks.com",
  }
end

