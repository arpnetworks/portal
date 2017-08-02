#!/usr/bin/env ruby

# Author: Garry
# Date  : 09-03-2013
#
# Refund a charge and reverse paid status of associated invoice(s)
#
# NOTE: Does not actually perform the refund, which must be done manually, but
# all "paperwork" associated with it is done

# Rails
APP_PATH = File.expand_path('../../../config/application', __FILE__)
require_relative '../../config/boot'
require APP_PATH
Rails.application.require_environment!

require 'date'

$CHARGE_ID = ARGV[0]
$TXN_ID    = ARGV[1]

if ARGV[0] == '--help'
  usage
  exit 1
end

def usage
  puts "./bin/refund.rb [charge_id] [txn_id]"
end

if $TXN_ID.nil?
  usage
  exit 1
end

$DATE_FORMAT = "%Y-%m-%d"
@today = Date.today.strftime($DATE_FORMAT)
@now = Time.now

charge = Charge.find $CHARGE_ID

if charge
  puts "Marking charge as refunded..."

  # TODO: Would be awesome if we actually performed the refund here

  charge.refunded_at = @now

  if charge.save
    puts "Done!"
  else
    puts "ERROR: Something went wrong..."
    exit 1
  end
else
  puts "Could not find charge with ID #{$CHARGE_ID}"
  exit 1
end

payments = Payment.where(reference_number: $TXN_ID)

payments.each do |payment|
  puts "Noting payment ##{payment.id} as refunded and setting payment amount to zero"
  payment.notes = "Refunded on #{@today}"
  payment.amount = 0

  if payment.save
    puts "Done!"
  else
    puts "ERROR: Something went wrong..."
  end

  payment.invoices.each do |invoice|
    if invoice.paid?
      puts "Marking invoice ##{invoice.id} as unpaid..."

      invoice.paid = false

      if invoice.save
        puts "Done!"
      else
        puts "ERROR: Something went wrong..."
      end
    end
  end
end
