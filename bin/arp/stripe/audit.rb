#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../config/application', __dir__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts 'ARP Networks vs Stripe Audit Report'
puts '==========' * 8

Account.where("stripe_customer_id != ''").each do |account|
  customer_id = account.stripe_customer_id
  puts account.display_account_name.to_s

  puts '  Stripe:'
  puts "    Customer ID: #{customer_id}"

  subs = Stripe::Subscription.list(customer: customer_id, status: 'active')

  our_mrc = account.mrc
  str_mrc = 0
  subs.each do |subscription|
    subscription['items']['data'].each do |subscription_item|
      if subscription_item['plan']['interval'] == 'month'
        str_mrc += (subscription_item['plan']['amount'] * subscription_item['quantity'])
      end
    end
  end

  str_mrc /= 100.0

  puts '    Total MRC in Stripe: ' + format('$%01.2f', str_mrc)
  puts '  Our MRC: ' + format('$%01.2f', account.mrc)

  if our_mrc != str_mrc
    puts ''
    puts ' *** MRC Discrepancy Detected *** '
    puts ''
  end

  puts '----------' * 8
end
