class ApplicationController < ActionController::Base
  before_action :clean_slate

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected

  def clean_slate
    @enable_admin_view = false
  end
end
