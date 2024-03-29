class ServicesController < ProtectedController
  before_action :find_service, only: %i[show update_label]
  before_action :check_cc_exists_and_current, only: %i[new confirm confirm_done]
  before_action :check_account_isnt_blank, only: %i[new confirm confirm_done]
  before_action :verify_service, only: %i[new confirm]
  before_action :verify_form, only: [:confirm]
  before_action :set_title, only: %i[new confirm confirm_done]

  def index
    @services = @account.services.active
    @service_totals = Service.give_me_totals(@services).sort
  end

  def show
    @services = [@service]
    @description = @service.description_source || ''

    # Resource details
    instantiate_resources_of_service(@service)

    if @service.service_code.name == 'VPS' ||
       @service.service_code.name == 'THUNDER'
      @iso_files = iso_files
    end
  end

  def update_label
    if params[:service]
      @service.label = params[:service][:label]
      @service.save

      @service.virtual_machines.each(&:build_and_reload_conserver!)

      flash[:notice] = 'Service label updated'
    end

    redirect_to(account_service_path(@account, @service))
  end

  def new
    @service = params[:service]

    render 'new_service_configurator', layout: 'responsive' if @service == 'vps_with_os'
  end

  # They confirm the new service / MRC to-be-created and also the pro-rated
  # invoice to-be-create
  def confirm
    if @account.offload_billing?
      @current_subscription = @account.stripe_subscription.current_subscription
    end

    case @service
    when 'vps', 'vps_with_os'
      plan = params[:plan]
      plan_struct = VirtualMachine.plans['vps'][plan]

      @billing_amount = plan_struct['mrc']
      @code           = 'VPS'
      @code_obj       = ServiceCode.find_by(name: @code)

      @service_title = if @service == 'vps_with_os'
                         VirtualMachine.os_display_name_from_code($CLOUD_OS, params[:os]) + ' VPS'
                       else
                         'Generic VM'
                       end

      @billing_amount_pro_rated = pro_rated_total(@billing_amount)

      @stripe_price_id = @account.offload_billing? ? $STRIPE_PRODUCTS['vps'][plan] : ""

      @pending_service = @account.services.create(
        pending: true,
        service_code: @code_obj,
        title: @service_title,
        billing_interval: 1,
        billing_amount: @billing_amount,
        stripe_price_id: @stripe_price_id
      )

      unless @account.offload_billing?
        @pending_invoice = @account.create_pro_rated_invoice!(
          @code, @service_title, @billing_amount_pro_rated, pending: true
        )
      end
    when 'metal'
      raise
    when 'thunder'
      raise
    when 'bgp'
      @billing_amount = 10.00
      @code           = 'BANDWIDTH'
      @code_obj       = ServiceCode.find_by(name: @code)
      @service_title  = "BGP Session (ASN #{params[:asn]})"
      @billing_amount_pro_rated = pro_rated_total(@billing_amount)

      @stripe_price_id = @account.offload_billing? ? $STRIPE_PRODUCTS['bgp'] : ""

      @pending_service = @account.services.create(
        pending: true,
        service_code: @code_obj,
        title: @service_title,
        billing_interval: 1,
        billing_amount: @billing_amount,
        stripe_price_id: @stripe_price_id,
        description: "Pending provisioning by ARP Networks staff.\n\nWe thank you for your patience!"
      )

      unless @account.offload_billing?
        @pending_invoice = @account.create_pro_rated_invoice!(
          @code, @service_title, @billing_amount_pro_rated, pending: true
        )
      end
    when 'backup'
      raise
    end

    @services = [@pending_service].compact
    @invoices = [@pending_invoice].compact

    @enable_pending_view = true

    session[:service_to_enable] = @service
    session[:pending_service_ids] = @services.map(&:id)
    session[:pending_invoice_ids] = @invoices.map(&:id)
  end

  def confirm_done
    # We've already done this step and maybe the user reloaded the page,
    # so go back to dashboard
    redirect_to dashboard_path if session[:service_to_enable].nil?

    @thank_you_message = :generic

    loc = session['form']['location']
    if %w[lax fra].include?(loc)
      @initial_vm_host = $PROVISIONING['initial_host'][loc]
    else
      raise "Invalid location: #{loc}"
    end

    session[:pending_service_ids].each do |service_id|
      service = Service.find(service_id)
      service.activate_billing!

      case session[:service_to_enable]
      when 'vps_with_os'
        provision_vps_with_os!(service)
        @thank_you_message = :vps_with_os
      when 'vps'
        plan = session[:form]['plan']
        plan_struct = VirtualMachine.plans['vps'][plan]

        os = session[:form]['os']

        # Mostly for informational purposes...
        Mailer.new_service_vps(@account,
                               plan,
                               session['form']['location'],
                               os,
                               plan_struct['bandwidth']).deliver_now

        os_template = case os
                      when '', 'linux'
                        'debian-8.0-amd64'
                      when 'freebsd'
                        'freebsd-11.0-amd64'
                      when 'openbsd-6.0-amd64'
                        'openbsd-6.0-amd64'
                      when 'ubuntu-14.04-amd64'
                        'ubuntu-14.04-amd64'
                      else
                        'debian-8.0-amd64'
                      end

        VirtualMachine.provision!(service,
                                  host: @initial_vm_host,
                                  ram: plan_struct['ram'],
                                  storage: plan_struct['storage'],
                                  os_template: os_template)
      end
    end

    session[:pending_invoice_ids].each do |invoice_id|
      invoice = Invoice.find(invoice_id)

      if @account.beta_billing_exempt?
        invoice.destroy
      else
        invoice.pending = false
        invoice.save
      end
    end

    case session[:service_to_enable]
    when 'bgp'
      Mailer.new_service_bgp(@account,
                             session['form']['asn'],
                             session['form']['full_routes'],
                             session['form']['prefixes'],
                             session['form']['location'],
                             session['form']['family']).deliver_now
    end

    session[:service_to_enable] = nil

    # Clear form session
    session[:form] = { errors: {} }
  end

  protected

  def find_service
    @service = @account.services.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find service with ID ##{params[:id]}"
    redirect_to(account_services_path(@account))
  end

  def check_cc_exists_and_current
    return if @account.beta_features? && @account.beta_billing_exempt?
    return if @account.offload_billing?

    if @account.credit_card.nil? || !@account.current?
      render 'new_gate'

      false
    end
  end

  def check_account_isnt_blank
    if @account.services.active.empty?
      render 'new_gate'

      false
    end
  end

  def verify_service
    @service = params[:service]

    if @service && %w[vps_with_os vps bgp].include?(@service)
      case @service
      when 'vps_with_os'
        return true # was beta
      else
        return true
      end
    end

    # Initialize form session
    session[:form] = { errors: {} }

    render('new_choose') && return
  end

  def verify_form
    begin
      case @service
      when 'vps', 'vps_with_os'
        # Make sure plan hasn't been messed with
        raise ArgumentError if VirtualMachine.plans['vps'][params[:plan]].nil?
        raise ArgumentError if params[:location].blank?

        if @service == 'vps_with_os'
          %i[os ipv4].each do |mandatory|
            raise ArgumentError if params[mandatory].blank?
          end

          session['form']['ipv4'] = params[:ipv4]
          session['form']['ssh_keys'] = params[:ssh_keys]
        end

        session['form']['location'] = params[:location]
        session['form']['plan'] = params[:plan]
        session['form']['os'] = params[:os]
      when 'metal'
        raise
      when 'thunder'
        raise
      when 'bgp'
        session['form']['asn'] = params[:asn]
        session['form']['full_routes'] = params[:full_routes]
        session['form']['prefixes'] = params[:prefixes]
        session['form']['location'] = params[:location]
        session['form']['family'] = params[:family]

        asn = params[:asn]

        if asn.blank?
          session[:form][:errors] = { asn: "ASN can't be blank" }
          redirect_to(new_account_service_path + "?service=#{@service}") && return
        end

        if asn !~ /^[0-9]+$/
          session[:form][:errors] = { asn: 'ASN can only contain numbers' }
          redirect_to(new_account_service_path + "?service=#{@service}") && return
        end
      when 'backup'
        raise
      end
    rescue ArgumentError => e
      redirect_to(new_account_service_path + "?service=#{@service}") && return
    end

    session[:form][:errors] = {}
  end

  def set_title
    case @service || session[:service_to_enable]
    when 'vps_with_os'
      @title = 'New Service Configurator'
    when 'vps'
      @title = 'New VPS without OS'
    when 'metal'
      @title = 'New ARP Metal™ Dedicated Server'
    when 'thunder'
      @title = 'New ARP Thunder™ Cloud Dedicated Server'
    when 'bgp'
      @title = 'New BGP Session'
    when 'backup'
      @title = 'New Backup Storage'
    end
  end

  # This came straight from create_new_vps_account.rb
  # But I modified the rescue amount to be full amount instead of 0
  def pro_rated_total(amount)
    todays_date = Time.now.strftime('%d').to_f
    end_of_month_date = Time.now.end_of_month.strftime('%d').to_f

    (1.0 - (todays_date / end_of_month_date)) * amount
  rescue StandardError
    amount
  end

  def provision_vps_with_os!(service)
    plan = session[:form]['plan']
    plan_struct = VirtualMachine.plans['vps'][plan]

    os = session[:form]['os']

    # Mostly for informational purposes...
    Mailer.new_service_vps_with_os(@account,
                                   plan,
                                   session['form']['location'],
                                   os,
                                   plan_struct['bandwidth']).deliver_now

    os_template = os

    ssh_keys_and_options = []
    session[:form]['ssh_keys']&.each do |id|
      ssh_keys_and_options << {
        id: id,
        opts: {
          password_plaintext: `/usr/bin/pwgen -nc 12 1`.strip,
          sudo_nopasswd: true
        }
      }
    end

    config_disk_options = {
      users: JSON.parse(SshKey.to_config_disk_json(ssh_keys_and_options)),
      arpnet_dk: session[:dk]
    }

    VirtualMachine.provision!(service,
                              host: @initial_vm_host,
                              ram: plan_struct['ram'],
                              storage: plan_struct['storage'],
                              os: VirtualMachine.os_display_name_from_code($CLOUD_OS, os, { version: true }),
                              os_template: os_template,
                              ip_address: session['form']['ipv4'],
                              do_config_disk: true,
                              config_disk_options: config_disk_options)
  end
end
