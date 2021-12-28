class PasswordChangeController < ProtectedController

  def create
    password_params = params.require(:account).permit(
      :current_password, :password, :password_confirmation
    )

    if current_account.update_with_password(password_params)
      flash[:notice] = I18n.t("devise.passwords.updated")
      bypass_sign_in current_account, scope: :account if sign_in_after_change_password?

      redirect_to account_security_path(current_account)
    else
      current_account.clean_up_passwords
      render "security/show"
    end
  end

end
