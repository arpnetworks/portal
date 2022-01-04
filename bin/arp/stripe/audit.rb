#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../config/application', __dir__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts 'ARP Networks vs Stripe Audit Report'
puts '==========' * 8

Account.where("stripe_customer_id != ''").each do |account|
  next unless account.offload_billing?

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

    if (discount = subscription['discount'])
      coupon = discount['coupon']

      if coupon
        puts "    Discount Coupon: #{coupon['name']}"
        if (percent_off = coupon['percent_off'])
          str_mrc = str_mrc - (str_mrc * (percent_off / 100))
        end
      end
    end
  end

  str_mrc /= 100.0

  formatted_str_mrc = format('$%01.2f', str_mrc)
  formatted_our_mrc = format('$%01.2f', our_mrc)

  puts '    Total MRC in Stripe: ' + formatted_str_mrc
  puts '  Our MRC: ' + formatted_our_mrc

  if formatted_our_mrc != formatted_str_mrc
    puts ''
    puts ' *** MRC Discrepancy Detected *** '
    puts ''
  end

  puts '----------' * 8
end
