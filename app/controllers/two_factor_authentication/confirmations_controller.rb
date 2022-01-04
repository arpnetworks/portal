module TwoFactorAuthentication
  class ConfirmationsController < ProtectedController

    def show
      redirect_to account_security_path(current_account)
    end

    def create
      if current_account.validate_and_consume_otp!(params.dig(:otp_code))
        current_account.otp_required_for_login = true
        @recovery_codes = current_account.generate_otp_backup_codes!
        current_account.save!

        render 'two_factor_authentication/confirmations/success'
      else
        flash.now[:alert] = "Failed to confirm the 2FA code"

        @qrcode = current_account.otp_qrcode
        render :new
      end
    end

  end
end