#!/usr/bin/env ruby
#
# A quick rip of bin/arp/cc/summary.rb adapted for QB journal entry format
# -- Garry (06-01-2024)

# Rails
APP_PATH = File.expand_path('../../../config/application', __dir__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

@period = 1.month.ago
@last_day_of_month = @period.end_of_month

@date = @period.strftime('%Y-%m-') + '%'

@payment_methods = ['Credit Card', 'Stripe']

output_csv_filename = "/tmp/#{Time.now.strftime('%m-%d-%Y-%s')}-qb-journals.csv"
f = File.open(output_csv_filename, 'w+')

f.puts 'JournalNo,JournalDate,AccountName,Debits,Credits,Description,Name,Currency,Location,Class'

@payment_methods.each do |payment_method|
  @totals = {}
  Payment.where("date like '#{@date}' and method = '#{payment_method}'").each do |payment|
    payment.invoices.each do |inv|
      inv.line_items.each do |li|
        @totals[li.code] = @totals[li.code].to_f + li.amount.to_f
      end
    end
  end

  payment_method_account = case payment_method
                           when 'Credit Card'
                             'PayPal'
                           when 'Stripe'
                             'Stripe'
                           end

  discriminator = 1.second.ago.strftime('%s').last(4)
  @journal_number = @last_day_of_month.strftime("%Y%m%d-#{discriminator}-#{payment_method_account}")

  grand_total = 0
  @totals.each do |code, total|
    account = case code
              when 'COLOCATION'
                'Sales:Hosting:Colocation'
              when 'BANDWIDTH'
                'Sales:Hosting:Bandwidth'
              when 'WEB_HOSTING'
                'Sales:Hosting:Web Hosting'
              when 'VPS'
                'Sales:Hosting:VPS'
              when 'MANAGED'
                'Sales:Hosting:Managed Services'
              when 'DISCOUNT'
                warn "Warning: DISCOUNT doesn't have an account in QB..."
                'Discounts'
              when 'IP_BLOCK'
                'Sales:Hosting:IP Numbers'
              when 'DOMAINS'
                'Sales:Hosting:Domain Names'
              when 'METAL'
                'Sales:Hosting:ARP Metal Dedicated Servers'
              when 'THUNDER'
                'Sales:Hosting:ARP Thunder Cloud Dedicated Servers'
              when 'BACKUP'
                'Sales:Hosting:Backup Services'
              else
                code
              end

    grand_total += total

    f.puts "#{@journal_number},,#{account},,#{money_without_currency_formatting(total)},,,,,"
  end

  last_day_of_month_formatted = @last_day_of_month.strftime('%m/%d/%Y')
  f.puts "#{@journal_number},#{last_day_of_month_formatted},#{payment_method_account},#{money_without_currency_formatting(grand_total)},,,,,,"
end

puts "Wrote: #{output_csv_filename}"
