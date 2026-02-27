class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #
  # IMPORTANT: This MUST be declared before any before_action that calls
  # current_account/current_user, because in Rails 6 protect_from_forgery
  # appends (not prepends) verify_authenticity_token. If a before_action
  # triggers Warden authentication before CSRF is checked, Devise's
  # clean_up_csrf_token_on_authentication hook regenerates the token,
  # causing InvalidAuthenticityToken.
  protect_from_forgery with: :exception

  before_action :clean_slate
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_if_migrated

  protected

  def clean_slate
    @enable_admin_view = false
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login, :otp_attempt])
  end

  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.respond_to?(:migrated?) && resource_or_scope.migrated? && resource_or_scope.migration_token.present?
      sign_out(resource_or_scope)
      phoenix_welcome_url(resource_or_scope.migration_token)
    else
      stored_location_for(resource_or_scope) || dashboard_path
    end
  end

  def redirect_if_migrated
    return unless current_account&.migrated? && current_account&.migration_token.present?

    token = current_account.migration_token
    sign_out(current_account)
    redirect_to phoenix_welcome_url(token), allow_other_host: true
  end

  def phoenix_welcome_url(token)
    host = Rails.env.production? ? "phoenix.arpnetworks.com" : "phoenix-staging.arpnetworks.com"
    "https://#{host}/welcome/#{token}"
  end

  def after_sign_out_path_for(resource_or_scope)
    new_account_session_path
  end
end
