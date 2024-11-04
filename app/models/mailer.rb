class Mailer < ApplicationMailer
  helper ActionView::Helpers::UrlHelper

  def swip_reassign_simple(form, downstream_org, ip_block)
    @subject    = 'REASSIGN SIMPLE API-2E8C-0886-4817-96AD'
    @recipients = ['hostmaster@arin.net']
    @from       = $NOTIFICATION_EMAILS.first

    @form           = form
    @ip_block       = ip_block
    @downstream_org = downstream_org

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def vps_monitoring_reminder(vm)
    account = vm.account

    @subject    = 'VPS Status'
    @recipients = [account.email]
    @cc         = $NOTIFICATION_EMAILS.first
    @from       = $SUPPORT_EMAIL

    @account = account
    @vm = vm

    mail(to: @recipients, subject: @subject, from: @from, cc: @cc)
  end

  def irr_route_object(action, prefix)
    raise 'action must be ADD or REMOVE' if action != 'ADD' && action != 'REMOVE'

    @subject    = "#{prefix.prefix} #{action} OBJECT"
    @recipients = 'auto-dbm@altdb.net'
    @from       = $IP_ADMIN_EMAIL

    additional = ''

    additional += "delete: No longer announced\n" if action == 'REMOVE'

    @prefix     = prefix
    @route_s    = prefix.version == 6 ? 'route6: ' : 'route:  '
    @changed    = Time.zone.now.strftime('%Y%m%d')
    @password   = $IRR_PASSWORD
    @additional = additional

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def irr_as_set(as_sets)
    @subject    = 'MODIFY OBJECT'
    @recipients = 'auto-dbm@altdb.net'
    @from       = $IP_ADMIN_EMAIL

    @members = as_sets.join(', ')

    @changed     = Time.zone.now.strftime('%Y%m%d')
    @password    = $IRR_PASSWORD
    @additional  = ''

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def new_service_bgp(account, asn, full_routes, prefixes, location, family)
    @subject    = 'ORDER: BGP Session'
    @recipients = $TICKET_EMAILS
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
    @subject    = 'ORDER: VPS without OS'
    @recipients = $TICKET_EMAILS
    @from       = account.email

    @account   = account
    @plan      = plan
    @location  = location
    @os        = os
    @bandwidth = bandwidth

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def new_service_vps_with_os(account, plan, location, os, bandwidth)
    @subject    = 'ORDER: Rapid VPS'
    @recipients = $TICKET_EMAILS
    @from       = account.email

    @account   = account
    @plan      = plan
    @location  = location
    @os        = os
    @bandwidth = bandwidth

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def new_order_from_stripe(setup_intent_id, product, customer)
    @subject    = 'Order from web site (Stripe)'
    @recipients = $TICKET_EMAILS
    @from       = $SUPPORT_EMAIL

    @setup_intent_id = setup_intent_id
    @product = product

    @location_code = @product[:location]
    
    @location = case @location_code
                when 'lax'
                  'Los Angeles'
                when 'fra'
                  'Frankfurt'
                else
                  @product[:location]
                end

    # Calculate IP block price
    @ip_block_price = case @product[:ip_block]
                      when '/29'
                        5
                      when '/28'
                        13
                      else # includes '/30'
                        0
                      end

    @customer = customer

    # Extra guards
    @product[:plan] ||= @product[:vps_plan]
    @product[:plan] ||= @product[:thunder_plan]

    # puts "The plan that we are sending to get_plan_details is: #{@product[:plan]}"
    # puts "The entire product object is: #{@product}"

    # Stop bombing out all the time if we don't have plan details
    @plan_details = get_plan_details(@product[:plan]) || {}

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def simple_notification(subject, body)
    @subject    = subject
    @recipients = $NOTIFICATION_EMAILS
    @from       = $SUPPORT_EMAIL

    @body = body

    mail(to: @recipients, subject: @subject, from: @from)
  end

  def welcome_new_customer(account, login, password)
    @subject    = 'Welcome to ARP Networks'
    @recipients = account.email
    @from       = $SUPPORT_EMAIL
    
    @account  = account
    @login    = login
    @password = password
    
    mail(to: @recipients, subject: @subject, from: @from)
  end

  def get_plan_details(plan_name)
    plan = VirtualMachine.plans['vps'][plan_name]
    return nil unless plan

    {
      os_label: VirtualMachine.os_display_name_from_code($CLOUD_OS, @product[:os_code]),
      os_version: @product[:os_code].split('-')[1], # Extracts version from something like 'freebsd-12.1-amd64'
      bandwidth: plan['bandwidth'],
      ram: plan['ram'],
      storage: plan['storage'],
      mrc: plan['mrc']
    }
  end
end
