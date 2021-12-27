class TwoFactorAuthenticationsController < ProtectedController

  def create
    current_account.otp_secret = Account.generate_otp_secret
    current_account.save!
    redirect_to new_account_two_factor_authentication_confirmation_path
  end

  def destroy
  end
end
