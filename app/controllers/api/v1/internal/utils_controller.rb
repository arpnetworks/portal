class Api::V1::Internal::UtilsController < ApiController
  before_action :trusted_vm_hosts,      only: [:console_logins]
  before_action :trusted_console_hosts, only: [:console_passwd_file]
  before_action :trusted_monitor_hosts, only: [:redis_ping, :job_queue_health]

  skip_before_action :verify_authenticity_token, only: [:console_logins]

  def console_logins
    if request.post?
      @body = request.body.read
      @response = ''

      @UUIDs = @body.split(',').map { |o| o.strip }

      @UUIDs.each do |uuid|
        vm = VirtualMachine.find_by_uuid(uuid)

        if vm
          begin
            account = vm.resource.service.account

            @response += "#{uuid}:#{vm.console_login}:#{vm.conserver_password}:#{vm.resource.service.label}\n"
          rescue
            nil
          end
        end
      end

      render plain: @response
    end
  end

  def console_passwd_file
    @admins = $ADMINS_CONSOLE

    @host = params[:host]

    if @host.nil? || @host.empty?
      @vm_hosts = Host.hosts_for_console_passwd_file
    else
      unless @host =~ /\./
        @host += '.arpnetworks.com'
      end

      @vm_hosts = [@host]
    end

    @file = ''
    @vm_hosts.each do |vm_host|
      @vms = VirtualMachine.where(["host = ?", vm_host])

      @vms.each do |vm|
        if !vm.serial_port.to_s.empty?
          (@admins + [vm.console_login]).uniq.each do |user|
            @file += "#{user}:#{vm.uuid}:#{vm_host}:#{vm.serial_port}:#{vm.label}:#{vm.vnc_port}:#{vm.resource.service.label}\n"
          end
        end
      end
    end

    render plain: @file
  end

  def redis_ping
    begin
      ARP_REDIS.ping
    rescue Exception => e
      render plain: e.message, status: 500
      return
    end

    render plain: "OK\n"
  end

  def job_queue_health
    failed_jobs = Job.failed.where(["updated_at >= ? and account_id not in (#{$JOBS_QUEUE_HEALTH_EXCLUSIONS.join(',')})", 24.hours.ago])

    if failed_jobs.empty?
      render plain: "OK\n"
    else
      num = failed_jobs.size
      render plain: "#{num} failed job(s)\n", status: 500
    end
  end
end
