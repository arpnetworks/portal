class ApplicationController < ActionController::Base
  before_action :clean_slate
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

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
      phoenix_host = Rails.env.production? ? "phoenix.arpnetworks.com" : "phoenix-staging.arpnetworks.com"
      "https://#{phoenix_host}/welcome/#{resource_or_scope.migration_token}"
    else
      stored_location_for(resource_or_scope) || dashboard_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_account_session_path
  end
end
