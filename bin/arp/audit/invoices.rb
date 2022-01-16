#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../config/application', __dir__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

audit_period = 7.days.ago

puts 'ARP Networks Invoices Audit Report                   ' + DateTime.now.strftime('%b %d, %Y %H:%M:%S %z')
puts '==========' * 8
puts ''
puts "The following accounts have more than 1 invoice created since: #{audit_period.strftime('%b %d, %Y')}"

accounts = {}

Invoice.where(['created_at > ?', audit_period]).each do |invoice|
  id = invoice.account.id

  accounts[id] ||= []
  accounts[id] << invoice
end

accounts.each do |account_id, invoices|
  next unless invoices.size > 1

  account = Account.find(account_id)

  puts account.display_account_name.to_s
  puts ''
  puts "  Has #{invoices.size} invoices:"

  invoices.each do |invoice|
    puts "    Invoice #{invoice.id}"
    puts "      Total: #{money2(invoice.total)}"
  end

  puts '----------' * 8
end
