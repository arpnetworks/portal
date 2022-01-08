class Accounts::Otp::SessionsController < DeviseController
  include OtpSessionExpirable

  prepend_before_action :require_no_authentication, only: [:new, :create]

  before_action :expire_otp_session!

  def new
    unless Account.exists?(session[:otp_account_id])
      session[:otp_account_id] = nil
      redirect_to new_account_session_path 
    end
  end

  def create
    account = warden.authenticate!(
      :otp_attempt_authenticatable,
      {
        scope: :account,
        recall: "#{controller_path}#new"
      }
    )
    otp_remember_me(account)

    flash[:notice] = "Welcome #{account.display_name}, it is nice to see you."
    sign_in(:account, account)

    respond_with account, location: after_sign_in_path_for(account)
  end

  private

  def otp_remember_me(account)
    return unless params[:otp_remember_me] == 'yes'

    default_session_options = Rails.configuration.session_options
    cookies.signed[:_arp_remember_me] = {
      value: [account.id, 30.days.after.utc.to_f.to_s],
      expires: 30.days.from_now,
      path: default_session_options[:path],
      domain: default_session_options[:domain],
      secure: default_session_options[:secure],
      httponly: true
    }
  end

end