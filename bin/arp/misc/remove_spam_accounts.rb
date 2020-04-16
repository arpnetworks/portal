#!/usr/bin/env ruby

require 'csv'

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

puts "Removing all accounts thought to be spammers..."

Account.remove_spam_accounts!

puts "Done!"
