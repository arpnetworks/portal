class ProtectedController < ApplicationController
  before_action :authenticate_account!

  protected

  def authenticate_account!(opts = {})
    super
    @account = current_account
  end

  def last_location
    request.get? ? request.url :
      (request.env["HTTP_REFERER"] || request.env["REQUEST_URI"])
  end

  def is_arp_admin?
    if @account && @account.arp_admin?
      return true
    else
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to new_account_session_path
      return false
    end
  end

  def is_arp_sub_admin?
    if (@account && @account.arp_sub_admin?) ||
        @account.arp_admin?
      return true
    else
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to new_account_session_path
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

      # Our identity
      raise ArgumentError if otp[0..11] != $OTP_PREFIX

      otp = Yubikey::OTP::Verify.new(otp)

      return true if otp.valid?

      raise ArgumentError
    rescue
      flash[:error] = "You took a wrong turn at Albuquerque"
      redirect_to new_account_session_path
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
      files = File.readlines("config/arp/iso-files.txt").map do |item|
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
