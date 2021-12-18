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
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login])
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_account_session_path
  end
end
