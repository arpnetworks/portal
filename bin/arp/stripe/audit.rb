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

    next unless (discount = subscription['discount'])
    next unless (coupon   = discount['coupon'])

    puts "    Discount Coupon: #{coupon['name']}"
    if (percent_off = coupon['percent_off'])
      str_mrc -= (str_mrc * (percent_off / 100))
    end
  end

  str_mrc /= 100.0

  formatted_str_mrc = format('$%01.2f', str_mrc)
  formatted_our_mrc = format('$%01.2f', our_mrc)

  puts "    Total MRC in Stripe: #{formatted_str_mrc}"
  puts "  Our MRC: #{formatted_our_mrc}"

  if formatted_our_mrc != formatted_str_mrc
    puts ''
    puts ' *** MRC Discrepancy Detected *** '
    puts ''

    ss = Stripe::SubscriptionSchedule.list(customer: customer_id)['data']
    if ss.size > 0
      puts ' However, subscription schedule(s) have been found:'
      ss.each do |sch|
        puts "    A subscription is scheduled (status=#{sch['status']})"
        puts "      ID: #{sch['id']}"
        sch['phases'].each do |phase|
          if (sd = phase['start_date'])
            puts "      Start date: #{Time.at(sd)}"
          end
        end
      end
    end
  end

  puts '----------' * 8
end

@accounts = Account.where("stripe_customer_id != '' and stripe_payment_method_id = ''")

if @accounts.size > 0
  puts ''
  puts "The following #{@accounts.size} #{'accounts'.pluralize(@accounts.size)} do not have a Stripe Payment Method ID:"
  puts ''
end

@accounts.each do |account|
  puts account.display_account_name
end
