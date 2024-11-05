#!/usr/bin/env ruby

require 'stripe'
require 'dotenv'
require 'optparse'

# Load environment variables
Dotenv.load

# Initialize options hash
options = {
  verbose: false
}

# Parse command line options
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} SETUP_INTENT_ID [-v]"

  opts.on("-v", "--verbose", "Run in verbose mode") do
    options[:verbose] = true
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Check for required setup intent ID argument
if ARGV.empty?
  puts "Error: Setup Intent ID is required"
  puts "Usage: #{$0} SETUP_INTENT_ID [-v]"
  exit 1
end

# Get setup intent ID from arguments
setup_intent_id = ARGV[0]

begin
  # Configure Stripe API key
  Stripe.api_key = ENV['STRIPE_API_KEY']

  # Retrieve setup intent and payment method
  setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)
  payment_method = Stripe::PaymentMethod.retrieve(setup_intent.payment_method)

  if options[:verbose]
    puts "Setup Intent"
    puts "-" * 12
    puts ""
    puts setup_intent
    puts "\nPayment Method"
    puts "-" * 14
    puts ""
    puts payment_method
  else
    # Just output the JSON objects
    puts setup_intent
    puts payment_method
  end

rescue Stripe::StripeError => e
  puts "Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  exit 1
end
