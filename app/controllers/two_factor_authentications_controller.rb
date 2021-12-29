class TwoFactorAuthenticationsController < ProtectedController

  def create
    current_account.otp_secret = Account.generate_otp_secret
    current_account.save!
    redirect_to new_account_two_factor_authentication_confirmation_path
  end

  def destroy
    current_account.otp_required_for_login = false
    current_account.otp_backup_codes&.clear
    current_account.save!
    redirect_to account_security_path(current_account)
  end
end
