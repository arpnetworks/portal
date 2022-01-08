# frozen_string_literal: true

class Accounts::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    Account.migrate_to_devise_password!(params[:account])

    self.resource = warden.authenticate!(:database_authenticatable, auth_options)

    if otp_required_for_login?(resource)
      sign_out(resource)
      session[:otp_account_id] = resource.id
      session[:otp_account_id_expires_at] = 30.seconds.after
      generate_derived_key

      redirect_to accounts_sign_in_otp_path
    else
      flash[:notice] = "Welcome #{resource.display_name}, it is nice to see you."
      sign_in(resource_name, resource)
      generate_derived_key

      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # A symmetric key used for encryption/decryption, derived from a
  # secret that only the user knows (e.g. their password)
  def generate_derived_key
    session[:dk] = resource.generate_derived_key(params[:account][:password])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  def otp_required_for_login?(resource)
    resource.otp_required_for_login? && otp_remember_me_is_inactive?(resource)
  end

  def otp_remember_me_is_inactive?(resource)
    resource_id, expires_at_epoch_seconds = cookies.signed[:_arp_remember_me]
    return true if expires_at_epoch_seconds.nil?
    expires_at = Time.at(expires_at_epoch_seconds.to_f)

    resource_id != resource.id || expires_at < Time.current
  end
end
