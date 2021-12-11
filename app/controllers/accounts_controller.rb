class AccountsController < ProtectedController
  protect_from_forgery

  def edit
    # Don't show password on form
    @account.password              = ''
    @account.password_confirmation = ''
  end

  def update
    # This field is protected from mass assignment
    @account.login = params[:account][:login]

    # If no new password was provided, remove it from params so we don't save
    # a blank password.
    if params[:account][:password] == ''
      params[:account].delete(:password)
      params[:account].delete(:password_confirmation)
    end

    if @account.update(account_params)
      flash[:notice] = 'Changes saved.'

      redirect_to edit_account_path(@account)
    else
      # Don't show password on form
      @account.password              = ''
      @account.password_confirmation = ''

      render action: 'edit'
    end
  end

  def show
    redirect_to action: 'edit'
  end

  # def login_attempt
  #   if params[:account] && (account = Account.authenticate(params[:account][:login],
  #                                                          params[:account][:password]))
  #     session[:account_id] = account.id
  #     account.visited_at = Time.zone.now unless account.visited_at
  #     account.update_attribute(:visited_at, Time.zone.now)

  #     cookies[:login] = { value: account.login, expires: 1.year.from_now }

  #     # A symmetric key used for encryption/decryption, derived from a
  #     # secret that only the user knows (e.g. their password)
  #     session[:dk] = account.generate_derived_key(params[:account][:password])

  #     flash[:notice] = "Welcome #{account.display_name}, it is nice to see you."
  #     redirect_back_or_default(dashboard_path) && (return true)
  #   else
  #     flash[:error] = 'Incorrect username and/or password, please try again.'
  #     redirect_to login_accounts_path
  #   end
  # end

  # def logout
  #   session[:account_id] = nil
  #   session[:human]      = nil
  #   cookies.delete(:login)
  #   flash[:notice] = 'You have been logged out.'
  #   redirect_to login_accounts_path
  # end

  ####################################
  # For the New Service Configurator #
  ####################################

  # To help with auto-assignment of IPs and/or customer selection of IP
  # addresses
  def ip_address_inventory
    location_code = params['location'] || 'lax'

    # Scope by location
    location = Location.find_by(code: location_code)
    if location.nil?
      respond_to do |format|
        format.json do
          render json: {
            error: "No such location: #{location_code}"
          }, status: :bad_request
        end
      end
      return
    end

    ips_available = @account.ips_available(location: location)
    ips_in_use    = @account.ips_in_use(location: location)

    # Start with an empty response
    @response = {}
    @ips      = {}

    selected_ip = nil
    selected_ip = session['form']['ipv4'] if session['form'] && session['form']['ipv4']

    ips_available.each do |ip|
      @ips[ip.to_s] = {
        ip_address: ip,
        assigned: false,
        assignment: nil,
        location: location.code,
        selected: (ip.to_s == selected_ip)
      }
    end
    ips_in_use.each do |ip|
      assignment = ''

      begin
        raise unless (vm = IpBlock.what_is_assigned_to(ip))

        assignment = vm.uuid

        if (service_id = vm.service_id)
          svc = Service.find(service_id)
          assignment = svc.label unless svc.label.empty?
        end
      rescue StandardError
        assignment = 'another instance'
      end

      next unless ip

      @ips[ip.to_s] = {
        ip_address: ip,
        assigned: true,
        assignment: assignment,
        location: location.code,
        selected: false
      }
    end

    @response['ips'] = @ips
    @response['location'] = location_code.upcase
    @response['caption'] = 'Please Choose'

    respond_to do |format|
      format.json { render json: @response }
    end
  end

  protected

  private

  def account_params
    params.require(:account).permit(
      :login,
      :email,
      :email2,
      :email_billing,
      :password,
      :password_confirmation,
      :company,
      :first_name,
      :last_name,
      :address1,
      :address2,
      :city,
      :state,
      :zip,
      :country
    )
  end
end
