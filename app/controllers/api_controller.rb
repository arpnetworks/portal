class ApiController < ApplicationController
  private

  def trusted_console_hosts
    @remote_ip = request.env['REMOTE_ADDR']

    if @remote_ip.in?($PROXY_HOSTS) || @remote_ip == '127.0.0.1'
       @remote_ip = request.env['HTTP_X_FORWARDED_FOR']
    end

    @hosts = $TRUSTED_CONSOLE_HOSTS

    unless @hosts.include?(@remote_ip)
      render :text => "Access denied from #{@remote_ip}\n", :status => 403 and return
    end
  end

  def trusted_vm_hosts
    @remote_ip = request.env['REMOTE_ADDR']

    if Rails.env == 'development'
      return true if @remote_ip == '127.0.0.1'
    end

    if @remote_ip.in?($PROXY_HOSTS) || @remote_ip == '127.0.0.1'
       @remote_ip = request.env['HTTP_X_FORWARDED_FOR']
    end

    @hosts = $TRUSTED_VM_HOSTS

    unless @hosts.include?(@remote_ip)
      render :text => "Access denied from #{@remote_ip}\n", :status => 403 and return
    end
  end

  def trusted_monitor_hosts
    # Let everyone in for now
    return true

    @remote_ip = request.env['REMOTE_ADDR']

    if @remote_ip.in?($PROXY_HOSTS) || @remote_ip == '127.0.0.1'
       @remote_ip = request.env['HTTP_X_FORWARDED_FOR']
    end

    @hosts = $TRUSTED_MONITOR_HOSTS

    unless @hosts.include?(@remote_ip)
      render :text => "Access denied from #{@remote_ip}\n", :status => 403 and return
    end
  end
end
