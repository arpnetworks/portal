module OtpSessionExpirable
  extend ActiveSupport::Concern

  included do
    private

    def expire_otp_session!
      return unless session[:otp_account_id]
      return unless session[:otp_account_id_expires_at]
      if session[:otp_account_id_expires_at] < Time.current
        session[:otp_account_id] = nil
        session[:otp_account_id_expires_at] = nil

        redirect_to new_account_session_path
      end
    end
  end
end