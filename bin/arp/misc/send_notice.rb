#!/usr/bin/env ruby

# Rails
APP_PATH = File.expand_path('../../../../config/application', __FILE__)
require_relative '../../../config/boot'
require APP_PATH
Rails.application.require_environment!

require 'optparse'
require 'mail'

def usage
  puts <<-HELP
  -n <node> REQUIRED (can be specified multiple times)

            Example: kvr03.arpnetworks.com
            Example: -n kvr03.arpnetworks.com -n kvr04.arpnetworks.com
  -f <file> REQUIRED
  -t <type> REQUIRED

            scheduled
            emergency
            outage

  -d        OPTIONAL

            Enable dry-run mode

            It'll just explain what will happen, but not actually send out
            any emails

  -a        OPTIONAL

            Enable admin-only mode

            Will send out emails to only Garry and Ben

            Good for testing full stack, but not actually notifying customers

  -s <addl> OPTIONAL

            Additional text to append to the subject line

  --everyone OPTIONAL

            Send notice to ALL active customers; overrides --node
HELP
end

# Defaults
nodes = []
file = nil
type = nil
dry  = nil
admins = nil
subject_additional = nil
everyone = nil

# Parse args
opts = OptionParser.new
opts.on("-n", "--node HOST", 'Notify customers on this HOST (can be specified multiple times)') { |o| nodes << o }
opts.on("-f", "--file FILE", 'Send notice in FILE to customers') { |o| file = o }
opts.on("-t", "--type scheduled|emergency|outage", 'Set notice type') { |o| type = o }
opts.on("-d", "--dry-run", 'Do not actually send emails') { |o| dry = o }
opts.on("-a", "--admins-only", 'Send notice to admins only') { |o| admins = o }
opts.on("-s", "--subject-additional TEXT", 'Append extra text to the subject') { |o| subject_additional = o }
opts.on("--everyone", 'Send notice to ALL active customers; overrides --node') { |o| everyone = o }
opts.parse(ARGV) rescue usage && exit

if nodes.empty? || file.nil? || type.nil?
  usage
  exit
end

if type != "scheduled" && type != "emergency" && type != "outage"
  puts "Unknown <type>: #{type}\n\n"

  usage
  exit
end

unless File.exists?(file)
  puts "Cannot find #{file}"

  exit 1
end

if everyone
  emails = Account.select { |o| o.active? }.map do |o|
    email  = o.email
    email2 = o.email2

    email  = email  =~ /@/ ? email  : nil
    email2 = email2 =~ /@/ ? email2 : nil

    [email, email2]
  end.flatten.compact.uniq.sort
else
  emails = nodes.map do |node|
    VirtualMachine.where(host: node).map do |o|
      email  = o.resource.service.account.email
      email2 = o.resource.service.account.email2

      email  = email  =~ /@/ ? email  : nil
      email2 = email2 =~ /@/ ? email2 : nil

      [email, email2]
    end
  end.flatten.compact.uniq.sort
end

@subject = nil
@body    = nil

case type
when 'scheduled'
  @subject = "ARP Networks, Inc. Scheduled Maintenance Notice"
when 'emergency'
  @subject = "ARP Networks, Inc. EMERGENCY Maintenance Notice"
when 'outage'
  @subject = "ARP Networks, Inc. Outage Report"
end

@subject += subject_additional.to_s

@body = File.read(file)

if dry
  puts "These are the emails I would send to:\n"
  puts emails
  puts ""
  puts "This is the subject I would use:\n"
  puts @subject
  puts ""
  puts "This is the email text I would use:\n"
  puts @body

  exit 1
end

admin_emails = %w(gdolley@arpnetworks.com ben@meh.net.nz)

if admins
  emails = admin_emails
else
  admin_emails.each do |email|
    emails << email
  end
end

subject = @subject

emails.each do |email|
  mail = Mail.new do
    from    'support@arpnetworks.com'
    to      email
    subject subject
    body    File.read(file)
  end
  mail.delivery_method :sendmail
  mail.deliver

  puts "Sent email to #{email}..."
end
