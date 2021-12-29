module TwoFactorAuthentication
  class RecoveryCodesController < ProtectedController

    def index
      redirect_to account_security_path(current_account)
    end

    def create
      @recovery_codes = current_account.generate_otp_backup_codes!
      current_account.save!
      render :index
    end

  end
end