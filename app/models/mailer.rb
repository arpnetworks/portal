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

  def new_order_from_stripe(setup_intent_id, product, customer, additional = {})
    @subject    = 'Order from web site (Stripe)'
    @recipients = $TICKET_EMAILS
    @from       = $SUPPORT_EMAIL

    set_order_attributes(setup_intent_id, product, customer, additional)
    mail(to: @recipients, subject: @subject, from: @from)
  end

  private

  def set_order_attributes(setup_intent_id, product, customer, additional)
    @setup_intent_id = setup_intent_id
    @product = product
    @customer = customer
    @additional = additional

    @location = translate_location(@product[:location])
    @ip_block_price = calculate_ip_block_price(@product[:ip_block])

    normalize_product_plan
    @plan_details = get_plan_details(@product[:plan], @product[:code]) || {}
  end

  def translate_location(code)
    case code
    when 'lax' then 'Los Angeles'
    when 'fra' then 'Frankfurt'
    else code
    end
  end

  def calculate_ip_block_price(block)
    case block
    when '/29' then 5
    when '/28' then 13
    when '/27' then 48
    else 0
    end
  end

  def normalize_product_plan
    @product[:plan] ||= @product[:vps_plan]
    @product[:plan] ||= @product[:thunder_plan]
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

  def get_plan_details(plan_name, product_code = 'vps')
    plan = VirtualMachine.plans[product_code][plan_name]
    return {} unless plan

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
