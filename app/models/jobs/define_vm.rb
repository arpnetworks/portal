class Jobs::DefineVM < Job
  def perform(args_json)
    args = JSON.parse(args_json)

    vm   = args['vm']['virtual_machine']

    return nil if vm['created_at'].nil?

    vm = VirtualMachine.find(vm['id'])

    job = super(vm.account, args_json)

    os, os_version, arch = vm.os_template.split('-')

    # Defaults
    iso = 'systemrescuecd-x86-4.6.1.iso'
    opt_params = {
      :cache => 'none',
      :io    => 'native',
      :disk_arch => 'virtio-scsi',
      :cpu_model => 'Westmere'
    }

    case os
    when 'freebsd'
      # Default
      iso = 'FreeBSD-11.0-RELEASE-amd64-disc1.iso'

      case os_version
      when /^9\./
        iso = 'FreeBSD-9.3-RELEASE-amd64-disc1.iso'
      when /^10\./
        iso = 'FreeBSD-10.3-RELEASE-amd64-disc1.iso'
      when /^11\./
        iso = 'FreeBSD-11.0-RELEASE-amd64-disc1.iso'
      end
    when 'openbsd'
      iso = 'OpenBSD-6.0-amd64-install60.iso'

      unless vm.cluster == 'kzt'
        opt_params[:cache] = 'writeback'
        opt_params[:io]    = 'threads'
      end

      opt_params[:disk_arch] = 'virtio' # OpenBSD can't do virtio-scsi yet
    when 'ubuntu'
      iso = 'ubuntu-' + os_version + '-server-amd64.iso'

      case os_version
      when '12.04'
        opt_params[:disk_arch] = 'virtio'
      when '14.04'
        opt_params[:disk_arch] = 'virtio'
      end
    when 'debian'
      iso = 'debian-' + os_version + '.0-amd64-netinst.iso'
    when 'centos'
      iso = 'CentOS-' + os_version + '-x86_64-netinstall.iso'
    end

    # Specific options / policies for ARP Thunder™ VMs
    if vm.cluster == 'sct'
      opt_params[:cpu_model] = 'SandyBridge'
      opt_params[:cpu_features] = ['vmx']
    end

    # Explicit pool?  No problem
    if vm.pool
      if vm.pool.pool_type == 'RBD'
        opt_params[:ceph_pool] = vm.pool_name
      end
    end

    work = {
      :class => 'DefineVmWorker',
      :args  => [job.id, job.jid,
                 vm.uuid, vm.label, 'x86_64', vm.ram,
                 vm.virtual_machines_interfaces.first.mac_address, vm.vlan,
                 vm.serial_port, vm.vnc_port, vm.websocket_port, vm.vnc_password,
                 iso, vm.cluster, opt_params],
      :jid   => job.jid,
      :retry => true,
      :enqueued_at => Time.now.to_f.to_s,
      :created_at  => Time.now.to_f.to_s
    }

    queue = vm.abbreviated_host

    ARP_REDIS.lpush("queue:#{queue}", work.to_json)

    job
  end
end