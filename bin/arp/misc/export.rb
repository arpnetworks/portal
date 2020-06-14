#!/usr/bin/env ruby

require 'csv'

# If we're running this from Spring, we'll already have APP_PATH
unless Object.const_defined?(:APP_PATH)
  # Rails
  APP_PATH = File.expand_path('../../../../config/application', __FILE__)
  require_relative '../../../config/boot'
  require APP_PATH
  Rails.application.require_environment!
end

puts "Email, Name, Company, Address, Customer Since, Cancellation Date, Suspension Date, Customer Type, Customer Status, Label, MRC, Balance"

starting = Process.clock_gettime(Process::CLOCK_MONOTONIC) if ENV['DEBUG']

Export.record_export!("Account") do |last_export|
  @accounts = Account.where("updated_at > ?", last_export).select do |a|
    # Weed out certain accounts
    a.email !~ /spam/ and
    a.email !~ /-DELETED/ and
    a.email !~ /-BANNED/ and
    a.email !~ /-DISABLED/ and
    !$EXPORT['exclusions']['account_ids'].include?(a.id) and

    # If you never had a service, then you're not in the list
    !a.services.empty? and

    # If you were never invoices, then you're not in the list either
    !a.invoices.empty?
  end.reverse

  @accounts.size
end

csv = CSV.generate do |csv|
  @accounts.each do |a|
    name = a.first_name.to_s + " " + a.last_name.to_s

    if name.to_s.strip.empty?
      name = a.login
    end

    unpaid = a.invoices.unpaid.inject(0) { |a, i| a + i.balance.to_f }

    csv << [a.email,
            name,
            a.company,
            a.address1.to_s.strip + ((a.address2 && !a.address2.empty?) ? ", #{a.address2.to_s.strip}" : "") + ", #{a.city.to_s.strip}, #{a.state.to_s.strip}, #{a.zip.to_s.strip}, #{a.country.to_s.strip}",
            a.customer_since,
            a.cancellation_date,
            a.vlan_shutdown_at,
            'Hosting',
            a.active? ? 'Current' : 'Former',
            if a.old_customer?
              'Old Customer'
            elsif a.suspended?
              'Suspended'
            elsif a.active?
              'Customer'
            else
              ''
            end,
            (a.mrc > 0) ? a.mrc : '',
            unpaid
    ]
  end
end

puts csv

if ENV['DEBUG']
  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  elapsed = ending - starting

  $stderr.puts "Elapsed time: #{elapsed}"
end
