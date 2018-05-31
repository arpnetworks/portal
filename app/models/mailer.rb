class Mailer < ActionMailer::Base
  helper ActionView::Helpers::UrlHelper

  def forgot_password(controller, account, new_password)
    raise "No new password provided" if new_password.nil? or new_password.blank?
    raise "Controller not specified" if controller.nil?

    @subject    = "ARP Networks Account Information"

    @controller   = controller
    @account      = account
    @new_password = new_password

    @recipients = account.email
    @from       = 'support@arpnetworks.com'
    @sent_on    = Time.now
    @headers    = { "Return-Path" => "support@arpnetworks.com" }

    mail(to: @recipients, subject: @subject, from: @from, cc: @cc, headers: @headers)
  end

  def swip_reassign_simple(form, downstream_org, ip_block)
    @subject    = "REASSIGN SIMPLE API-2E8C-0886-4817-96AD"
    @recipients = ["hostmaster@arin.net"]
    @from       = "gdolley@arpnetworks.com"

    @form           = form
    @ip_block       = ip_block
    @downstream_org = downstream_org

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def vps_monitoring_reminder(vm)
    account = vm.account

    @subject    = "VPS Status"
    @recipients = [account.email]
    # @recipients = "gdolley@arpnetworks.com"
    @cc         = "gdolley@arpnetworks.com"
    @from       = "support@arpnetworks.com"

    @account = account
    @vm = vm

    mail(to: @recipients, subject: @subject, from: @from, cc: @cc)
  end

  def irr_route_object(action, prefix)
    raise "action must be ADD or REMOVE" if action != 'ADD' && action != 'REMOVE'

    @subject    = "#{prefix.prefix} #{action} OBJECT"
    # @recipients = "gdolley@arpnetworks.com"
    @recipients = "auto-dbm@altdb.net"
    @from       = "ip-admin@arpnetworks.com"

    additional = ''

    if action == 'REMOVE'
      additional += "delete: No longer announced\n"
    end

    @prefix     = prefix
    @route_s    = prefix.version == 6 ? 'route6: ' : 'route:  '
    @changed    = Time.new.strftime("%Y%m%d")
    @password   = $IRR_PASSWORD
    @additional = additional

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def irr_as_set(as_sets)
    @subject    = "MODIFY OBJECT"
    # @recipients = "gdolley@arpnetworks.com"
    @recipients = "auto-dbm@altdb.net"
    @from       = "ip-admin@arpnetworks.com"

    @members    = as_sets.join(', ')

    @changed     = Time.new.strftime("%Y%m%d")
    @password    = $IRR_PASSWORD
    @additional  = ''

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def new_service_bgp(account, asn, full_routes, prefixes, location, family)
    @subject    = "ORDER: BGP Session"
    @recipients = ["gdolley+tickets@arpnetworks.com", "ben@arpnetworks.com"]
    @from       = account.email

    @account  = account
    @asn      = asn
    @prefixes = prefixes
    @location = location
    @family   = family
    @full_routes = full_routes

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def new_service_vps(account, plan, location, os, bandwidth)
    @subject    = "ORDER: VPS without OS"
    @recipients = ["gdolley+tickets@arpnetworks.com", "ben@arpnetworks.com"]
    @from       = account.email

    @account   = account
    @plan      = plan
    @location  = location
    @os        = os
    @bandwidth = bandwidth

    mail(to: @recipients, subject: @subject, from: @from)
  end
end
