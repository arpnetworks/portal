class AccountsController < ProtectedController
  protect_from_forgery :except => [:login_attempt, :login]

  skip_before_filter :login_required, :only => [:new, :create,
    :forgot_password, :forgot_password_post, :login, :login_attempt]

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(params.require(:account).permit(
      :login,
      :email,
      :password,
      :password_confirmation
    ))

    if @account.save
      session[:account_id] = @account.id
      flash[:notice] = 'Your account has been created!'

      redirect_to :controller => 'my_account', :action => 'dashboard'
    else
      render :action => 'new'
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
      flash[:notice] = "Changes saved."

      # Return to edit page
      redirect_to :action => 'edit' and return
    end

    # Don't show password on form
    @account.password              = ''
    @account.password_confirmation = ''

    render :action => 'edit'
  end

  def show
    redirect_to :action => 'edit'
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
    redirect_to(forgot_password_accounts_path, :email => params[:email])
  end

  def login
    # Already logged in?  Go to Dashboard
    if session[:account_id]
      flash[:notice] = "You're already logged in, redirecting to your Dashboard"
      redirect_to(dashboard_path)
    end
  end

  def login_attempt
    if params[:account] && account = Account.authenticate(params[:account][:login], params[:account][:password])
      session[:account_id] = account.id
      account.visited_at = Time.now unless account.visited_at
      account.update_attribute(:visited_at, Time.now)

      cookies[:login] = { :value => account.login, :expires => 1.year.from_now }

      flash[:notice] = "Welcome #{account.display_name}, it is nice to see you."
      redirect_back_or_default(dashboard_path) and return true
    else
      flash[:error] = 'Incorrect username and/or password, please try again.'
      redirect_to login_accounts_path
    end
  end

  def logout
    session[:account_id] = nil
    session[:human]   = nil
    cookies.delete(:login)
    flash[:notice] = "You have been logged out."
    redirect_to login_accounts_path
  end

  protected

  # From http://www.bigbold.com/snippets/posts/show/491
  def newpass(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
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
