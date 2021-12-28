class Accounts::Otp::SessionsController < DeviseController
  prepend_before_action :require_no_authentication, only: [:new, :create]

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

    flash[:notice] = "Welcome #{account.display_name}, it is nice to see you."
    sign_in(:account, account)

    respond_with account, location: after_sign_in_path_for(account)
  end

end