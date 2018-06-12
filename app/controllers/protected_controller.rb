class ProtectedController < ApplicationController
  before_filter :login_required

  protected

  def login_required
    if logged_in?
      @account = Account.find(session[:account_id])
      true
    else
      store_location
      flash[:error] = "You must be logged in to the see this page."
      redirect_to login_accounts_path and return false
    end
  end

  def logged_in?
    session[:account_id] || false
  end

  def store_location
    session[:return_to] = last_location
  end

  def last_location
    request.get? ? request.url :
      (request.env["HTTP_REFERER"] || request.env["REQUEST_URI"])
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def is_arp_admin?
    if @account && @account.arp_admin?
      return true
    else
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to login_accounts_path
      return false
    end
  end

  def is_arp_sub_admin?
    if @account && @account.arp_sub_admin?
      return true
    else
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to login_accounts_path
      return false
    end
  end

  # For services
  def instantiate_resources_of_service(service)
    @resources = service.resources
    @ip_blocks = service.ip_blocks.sort do |a, b|
      a.version <=> b.version # IPv4 to appear before IPv6
    end
  end

  def verify_otp
    begin
      otp = params[:otp]

      raise ArgumentError unless otp



      otp = Yubikey::OTP::Verify.new(otp)

      return true if otp.valid?

      raise ArgumentError
    rescue
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to login_accounts_path
      return false
    end
  end

  # For dispatcher, originally from VM controller
  def write_request(vm, action, other = nil)
    ts = Time.new.to_i
    File.open("tmp/requests/#{vm.uuid}-#{ts}", "w") do |f|
      f.puts "#{action} #{vm.uuid} #{vm.host} #{other}"
    end
  end

  def iso_files
    begin
      files = File.readlines("config/iso-files.txt").map do |item|
        item.strip
      end

      files.sort do |a,b|
        a.downcase <=> b.downcase
      end
    rescue
      []
    end
  end
end
