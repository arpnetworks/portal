#!/usr/bin/env ruby

require 'csv'

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts "Email, Name, Company, Address, Customer Since, Cancellation Date, Customer Type, Customer Status, Label, MRC"

accounts = Account.all.select do |a|
  # Weed out certain accounts
  a.email !~ /spam/ and
  a.email !~ /-DELETED/ and
  a.email !~ /-BANNED/ and

  # If you never had a service, then you're not in the list
  !a.services.empty?
end.reverse

# TODO: Some kind of "Paid up? Yes/no" field

csv = CSV.generate do |csv|
  accounts[0..30].each do |a|
    csv << [a.email,
            a.first_name.to_s + " " + a.last_name.to_s,
            a.company,
            a.address1.to_s.strip + ((a.address2 && !a.address2.empty?) ? ", #{a.address2.to_s.strip}" : "") + ", #{a.city.to_s.strip}, #{a.state.to_s.strip}, #{a.zip.to_s.strip}, #{a.country.to_s.strip}",
            a.customer_since,
            a.cancellation_date,
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
            (a.mrc > 0) ? a.mrc : ''
    ]
  end
end

puts csv
