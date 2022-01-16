#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../config/application', __dir__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts 'ARP Networks vs Stripe Audit Report                  ' + DateTime.now.strftime('%b %d, %Y %H:%M:%S %z')
puts '==========' * 8

monthly = {
  interval: 'month',
  interval_count: 1
}
semiannual = {
  interval: 'month',
  interval_count: 6
}
annual = {
  interval: 'year',
  interval_count: 1
}

our_recurring_totals = {
  '1' => 0,
  '6' => 0,
  '12' => 0
}
str_recurring_totals = {
  '1' => 0,
  '6' => 0,
  '12' => 0
}

Account.where("stripe_customer_id != ''").each do |account|
  next unless account.offload_billing?

  customer_id = account.stripe_customer_id
  puts account.display_account_name.to_s

  puts '  Stripe:'
  puts "    Customer ID: #{customer_id}"

  [monthly, semiannual, annual].each do |period|
    interval = period[:interval]
    count = period[:interval_count]

    case interval
    when 'month'
      our_mrc = account.arc(count)
      str_mrc = 0

      interval_label = count == 6 ? '(Every 6 months)' : ''
      totals_key = count.to_s
    when 'year'
      our_mrc = account.yrc
      str_mrc = 0

      interval_label = '(Annual)'
      totals_key = '12'
    end

    # On second thought, don't skip this, since there might be a dangling subscription in Stripe
    # that we don't know about.  This is an audit script, after all...
    # next unless our_mrc > 0

    subs = Stripe::Subscription.list(customer: customer_id, status: 'active')

    subs.each do |subscription|
      subscription['items']['data'].each do |subscription_item|
        if subscription_item['plan']['interval'] == interval &&
           subscription_item['plan']['interval_count'] == count
          str_mrc += (subscription_item['plan']['amount'] * subscription_item['quantity'])
        end
      end

      next if str_mrc == 0
      next unless (discount = subscription['discount'])
      next unless (coupon   = discount['coupon'])

      puts "    Discount Coupon: #{coupon['name']}"
      if (percent_off = coupon['percent_off'])
        str_mrc -= (str_mrc * (percent_off / 100))
      end
    end

    str_mrc /= 100.0

    next if our_mrc == 0 && str_mrc == 0

    formatted_str_mrc = format('$%01.2f', str_mrc)
    formatted_our_mrc = format('$%01.2f', our_mrc)

    our_recurring_totals[totals_key] += our_mrc
    str_recurring_totals[totals_key] += str_mrc

    puts "    Total MRC in Stripe: #{formatted_str_mrc} #{interval_label}"
    puts "  Our MRC: #{formatted_our_mrc}"

    next unless formatted_our_mrc != formatted_str_mrc

    puts ''
    puts ' *** MRC Discrepancy Detected *** '
    puts ''

    ss = Stripe::SubscriptionSchedule.list(customer: customer_id)['data']
    ss = ss.reject do |sch|
      sch['status'] == 'canceled'
    end
    next unless ss.size > 0

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

  puts '----------' * 8
end

puts <<~HERE

  Grand Totals
  ~~~~~~~~~~~~

  Our Recurring Monthly Total: #{money2(our_recurring_totals['1'])}
  Our Recurring Semiannual Total: #{money2(our_recurring_totals['6'])}
  Our Recurring Annual Total: #{money2(our_recurring_totals['12'])}

  Stripe Recurring Monthly Total: #{money2(str_recurring_totals['1'])}
  Stripe Recurring Semiannual Total: #{money2(str_recurring_totals['6'])}
  Stripe Recurring Annual Total: #{money2(str_recurring_totals['12'])}

  NOTE: We should reconcile our bank statement against these totals.
HERE

@accounts = Account.where("stripe_customer_id != '' and stripe_payment_method_id = ''")

if @accounts.size > 0
  puts ''
  puts "The following #{@accounts.size} #{'accounts'.pluralize(@accounts.size)} do not have a Stripe Payment Method ID:"
  puts ''
end

@accounts.each do |account|
  puts account.display_account_name
end
