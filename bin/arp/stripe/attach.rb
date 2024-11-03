#!/usr/bin/env ruby

require 'stripe'
require 'dotenv'
require 'optparse'

# Load environment variables
Dotenv.load

  # Configure Stripe API key
  Stripe.api_key = ENV['STRIPE_API_KEY']


# Simplify option parser
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} SETUP_INTENT_ID CUSTOMER_ID"

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Check for required arguments
if ARGV.length < 2
  puts "Error: Setup Intent ID and Customer ID are required"
  puts "Usage: #{$0} SETUP_INTENT_ID CUSTOMER_ID"
  exit 1
end

# Get arguments from ARGV
setup_intent_id = ARGV[0]
customer_id = ARGV[1]

begin
  setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)
  customer = Stripe::Customer.retrieve(customer_id)

  Stripe::PaymentMethod.attach(setup_intent.payment_method, customer: customer_id)

  puts "Payment method attached to customer"
  
rescue Stripe::StripeError => e
  puts "Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  exit 1
end