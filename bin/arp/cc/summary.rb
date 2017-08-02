#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../config/application', __FILE__)
require_relative '../../config/boot'
require APP_PATH
Rails.application.require_environment!

@period = 1.month.ago

@date = @period.strftime("%Y-%m-") + '%'

@totals = {}
Payment.where("date like '#{@date}' and method = 'Credit Card'").each do |payment|
  payment.invoices.each do |inv|
    inv.line_items.each do |li|
      @totals[li.code] = @totals[li.code].to_f + li.amount.to_f
    end
  end
end

puts "Payment Summary by Credit Card for #{@period.strftime("%B %Y")}\n\n"

grand_total = 0
@totals.each do |code, total|
  friendly = case code
             when 'COLOCATION'
               'Colocation'
             when 'BANDWIDTH'
               'Bandwidth / IP Transit'
             when 'WEB_HOSTING'
               'Web Hosting'
             when 'VPS'
               'VPS'
             when 'MANAGED'
               'Managed Services'
             when 'DISCOUNT'
               'Discounts'
             when 'IP_BLOCK'
               'IP Numbers'
             when 'DOMAINS'
               'Domain Names'
             when 'METAL'
               'Dedicated Servers'
             when 'THUNDER'
               'ARP Thunder(tm) Cloud Dedicated Servers'
             when 'BACKUP'
               'Backup Services'
             else
               code
             end

  grand_total += total
  puts friendly + ": " + money(total)
end

puts "\n"
puts "Grand Total: " + money(grand_total)
