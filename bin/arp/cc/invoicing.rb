#!/usr/bin/env ruby
#
# Author: Garry
# Date  : 01-11-2012
#
# Create invoices for all monthly recurring customers

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

require 'date'

$ORDER = ARGV[0]

if ARGV[0] == '--help'
  usage
  exit 1
end

def usage
  puts "./invoicing.rb"
end

$DEBUG = false

$BILLING_INTERVAL = 1
$BILLING_DUE_ON = nil

$DATE_FORMAT = "%Y-%m-%d"

def invoice_accounts!(accounts)
  puts ""

  accounts.each do |a|
    next if a.in_stripe? # Accounts in Stripe are invoiced automatically

    begin
      account_string = "#{a.display_account_name} (#{a.id}):"

      if $BILLING_INTERVAL > 1
        services_to_bill = a.services.active.select do |s|
          s.billing_interval == $BILLING_INTERVAL && s.billing_amount > 0 &&
                                s.billing_due_on.strftime($DATE_FORMAT) == $BILLING_DUE_ON
        end
      else
        services_to_bill = a.services.active.select do |s|
          s.billing_interval == $BILLING_INTERVAL && s.billing_amount > 0
        end
      end

      extra_msg = ''
      if $BILLING_INTERVAL > 1
        extra_msg = "Billing Term: #{$BILLING_INTERVAL} months. "
      end

      invoice = Service.create_invoice(a, services_to_bill,
                                       :terms => 'Due upon receipt',
                                       :message => extra_msg + 'Thank you for your business',
                                       :date => $BILLING_DUE_ON || Time.now)

      total = invoice.total.to_f
      @total_invoiced += total

      puts "Invoiced #{account_string} for #{money(total)}... "

      if $BILLING_INTERVAL > 1
        services_to_bill.each do |service|
          puts "  Service ID: #{service.id}"
          puts "  Current service.billing_due_on: #{service.billing_due_on}"

          next_billing_due_on = service.billing_due_on + $BILLING_INTERVAL.months
          service.billing_due_on = next_billing_due_on

          if service.save
            puts "  Set next billing date for #{service.title} to #{service.billing_due_on}"
          else
            puts "  ERROR: Could not set next billing date"
          end
        end
      end
    rescue Exception => e
      puts ""
      puts "Received exception: #{e}"
      puts "#{e.backtrace.to_yaml}"
      puts "Continuing..."
    end
  end
end

def warning!
  puts ""
  puts "*** WARNING ***"
  puts ""
  puts "This will create new invoices for all monthly recurring customers."
  puts ""
  puts "BILLING_INTERVAL: #{$BILLING_INTERVAL}"
  puts "BILLING_DUE_ON: #{$BILLING_DUE_ON}"
  puts ""
  puts "*** WARNING ***"
  puts ""

  continue?
end

def main
  go = warning!

  if go
    base_conditions = "billing_interval = #{$BILLING_INTERVAL} and billing_amount > 0"
    if $BILLING_DUE_ON.nil?
      if $BILLING_INTERVAL == 1
        conditions = base_conditions
      else
        fail "$BILLING_INTERVAL is != 1 yet $BILLING_DUE_ON is nil"
      end
    else
      conditions = "#{base_conditions} and billing_due_on = '#{$BILLING_DUE_ON}'"
    end

    puts "  conditions: #{conditions}" if $DEBUG

    monthly_services = Service.active.where(conditions)
    accounts = monthly_services.map { |s| s.account }.uniq

    # These guys are invoiced in another system or otherwise skipped
    skip = []

    accounts = accounts.select { |a| !skip.include?(a.company) }

    @total_invoiced = 0

    invoice_accounts!(accounts)

    puts ""
    puts "Total Invoiced: " + money(@total_invoiced)
  end
end

@today = Date.today.strftime($DATE_FORMAT)

puts ""
puts "Before we begin, let me report about services that have renewals prior to #{@today}"
puts ""

services = Service.active.where("billing_due_on < '#{@today}' and billing_amount > 0")

services.each do |service|
  puts "ID: #{service.id}"
  puts "Account ID: #{service.account.id}"
  puts "Title: #{service.title}"
  puts "Amount: #{service.billing_amount}"
  puts "Due On: #{service.billing_due_on}"
end

main

$BILLING_DUE_ON = Date.today.beginning_of_month.strftime($DATE_FORMAT)

[3, 6, 12, 24, 36].each do |interval|
  $BILLING_INTERVAL = interval
  main
end
