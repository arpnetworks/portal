#!/usr/bin/env ruby
#
# Author: Garry
# Date  : 12-22-2011
#
# Print a charge report

# If we're running this from Spring, we'll already have APP_PATH
unless Object.const_defined?(:APP_PATH)
  # Rails
  APP_PATH = File.expand_path('../../../config/application', __dir__)
  require_relative '../../../config/boot'
  require APP_PATH
  Rails.application.require_environment!
end

include Format

$ORDER = $ARGV[0]

if $ARGV[0] == '--help'
  usage
  exit 1
end

def usage
  puts './reporting.rb [order]'
end

def main
  monthly_services = Service.active.where('billing_interval = 1 and billing_amount > 0')
  accounts = monthly_services.map { |s| s.account }.uniq

  # These guys are invoiced
  skip = []

  if $ORDER == 'mrc'
    accounts.sort! { |a, b| a.mrc <=> b.mrc }
  else
    accounts.sort! { |a, b| a.display_account_name.upcase <=> b.display_account_name.upcase }
  end

  total = 0
  accounts.each do |a|
    next if skip.include?(a.company)

    account_string = "#{a.display_account_name} (#{a.id}):"
    num_of_spaces = 60 - account_string.length

    num_of_spaces = 1 if num_of_spaces < 0

    spacer = ' ' * num_of_spaces
    puts "#{account_string} #{spacer} #{a.mrc(formatted: true)}"

    puts '   WARNING!  This account does not have a credit card' if a.credit_card.nil?

    total += a.mrc
  end

  puts ''
  puts 'Total: ' + money(total)
end

main
