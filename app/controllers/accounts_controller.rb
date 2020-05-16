class AccountsController < ProtectedController
  protect_from_forgery except: %i[login_attempt login]

  skip_before_filter :login_required, only: %i[new
                                               create
                                               forgot_password
                                               forgot_password_post
                                               login
                                               login_attempt]

  def new
    @account = Account.new
  end

  def create
    params[:account][:password] = params[:account][:password]
    params[:account][:password_confirmation] = \
      params[:account][:password_confirmation]

    @account = Account.new(params.require(:account).permit(
                             :login,
                             :email,
                             :password,
                             :password_confirmation
                           ))

    if @account.save
      session[:account_id] = @account.id
      flash[:notice] = 'Your account has been created!'

      redirect_to controller: 'my_account', action: 'dashboard'
    else
      render action: 'new'
    end
  end

  def edit
    @account = Account.find(session[:account_id])

    # Don't show password on form
    @account.password              = ''
    @account.password_confirmation = ''
  end

  def update
    @account = Account.find(session[:account_id])

    # This field is protected from mass assignment
    @account.login = params[:account][:login]

    # If no new password was provided, remove it from params so we don't save
    # a blank password.
    if params[:account][:password] == ''
      params[:account].delete(:password)
      params[:account].delete(:password_confirmation)
    end

    if @account.update_attributes(account_params)
      flash[:notice] = 'Changes saved.'

      # Return to edit page
      redirect_to action: 'edit' and return
    end

    # Don't show password on form
    @account.password              = ''
    @account.password_confirmation = ''

    render action: 'edit'
  end

  def show
    redirect_to action: 'edit'
  end

  def forgot_password_post
    @email = params[:email]

    if @email.nil? || @email.blank?
      flash[:notice] = 'Please enter your email address'
    else
      @account = Account.find_by_email(@email)
      raise ActiveRecord::RecordNotFound unless @account

      @new_password = newpass(8)
      @account.password = @account.password_confirmation = @new_password
      @account.save! # Raise an exception if this can't be saved

      Mailer.forgot_password(self, @account, @new_password).deliver_now

      flash[:notice] = "Thank you, your account details have been sent to #{@email}."
    end

    redirect_to forgot_password_accounts_path
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Sorry, we can't find an account with that email address."
    redirect_to(forgot_password_accounts_path, email: params[:email])
  end

  def login
    return unless session[:account_id]

    # Already logged in?  Go to Dashboard
    flash[:notice] = "You're already logged in, redirecting to your Dashboard"
    redirect_to(dashboard_path)
  end

  def login_attempt
    if params[:account] && (account = Account.authenticate(params[:account][:login],
                                                           params[:account][:password]))
      session[:account_id] = account.id
      account.visited_at = Time.now unless account.visited_at
      account.update_attribute(:visited_at, Time.now)

      cookies[:login] = { value: account.login, expires: 1.year.from_now }

      flash[:notice] = "Welcome #{account.display_name}, it is nice to see you."
      redirect_back_or_default(dashboard_path) and return true
    else
      flash[:error] = 'Incorrect username and/or password, please try again.'
      redirect_to login_accounts_path
    end
  end

  def logout
    session[:account_id] = nil
    session[:human]      = nil
    cookies.delete(:login)
    flash[:notice] = 'You have been logged out.'
    redirect_to login_accounts_path
  end

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

    ips_available.each do |ip|
      @ips[ip.to_s] = {
        ip_address: ip,
        assigned: false,
        assignment: nil,
        location: location.code
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

      if ip
        @ips[ip.to_s] = {
          ip_address: ip,
          assigned: true,
          assignment: assignment,
          location: location.code
        }
      end
    end

    @response['ips'] = @ips
    @response['caption'] = 'Please Choose an IP in ' + \
                           location_code.upcase

    respond_to do |format|
      format.json { render json: @response }
    end
  end

  protected

  # From http://www.bigbold.com/snippets/posts/show/491
  def newpass(len)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    newpass = ''
    1.upto(len) { |i| newpass << chars[rand(chars.size - 1)] }
    newpass
  end

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
