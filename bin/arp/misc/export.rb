#!/usr/bin/env ruby

require 'csv'

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts "Email, Name, Company, Address, Customer Since, Cancellation Date, Customer Type, Customer Status, Label"

accounts = Account.all.select do |a|
  # Weed out certain accounts
  a.email !~ /spam/ and
  a.email !~ /-DELETED/ and
  a.email !~ /-BANNED/ and

  # If you never had a service, then you're not in the list
  !a.services.empty?
end.reverse

# TODO: Export real-time MRC
# TODO: Suspension status

csv = CSV.generate do |csv|
  accounts[10..20].each do |a|
    csv << [a.email,
            a.first_name.to_s + " " + a.last_name.to_s,
            a.company,
            a.address1.to_s + ((a.address2 && !a.address2.empty?) ? ", #{a.address2.to_s}" : "") + ", #{a.city.to_s}, #{a.state.to_s}, #{a.zip.to_s}, #{a.country.to_s}",
            a.customer_since,
            a.cancellation_date,
            'Hosting',
            a.active? ? 'Current' : '',
            if a.old_customer?
              'Old Customer'
            elsif a.active?
              'Customer'
            else
              ''
            end
    ]
  end
end

puts csv
