module TwoFactorAuthentication
  class RecoveryCodesController < ProtectedController

    def create
      @recovery_codes = current_account.generate_otp_backup_codes!
      current_account.save!
      render :index
    end

  end
end