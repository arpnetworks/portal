class Jobs::DefineVm < Job
  def perform(args_json)
    args = JSON.parse(args_json)

    vm   = args['vm']['virtual_machine']

    if vm.nil?
      vm = args['vm']
    end

    return nil if vm['created_at'].nil?

    vm = VirtualMachine.find(vm['id'])

    job = super(vm.account, args_json)

    os, os_version, arch = vm.os_template.split('-')

    # Defaults
    iso = 'systemrescuecd-amd64-6.1.5.iso'
    opt_params = {
      :cache => 'none',
      :io    => 'native',
      :disk_arch => 'virtio-scsi',
      :cpu_model => 'Westmere'
    }

    case os
    when 'freebsd'
      # Default
      iso = 'FreeBSD-12.2-RELEASE-amd64-disc1.iso'

      case os_version
      when /^9\./
        iso = 'FreeBSD-9.3-RELEASE-amd64-disc1.iso'

        if cluster =~ /^[ks]ct/
          opt_params[:cache] = 'writeback'
          opt_params[:io]    = 'threads'
        end
      when /^10\./
        iso = 'FreeBSD-10.3-RELEASE-amd64-disc1.iso'
      when /^11\./
        iso = 'FreeBSD-11.3-RELEASE-amd64-disc1.iso'
      end
    when 'openbsd'
      case os_version
      when /^6\.7/
        iso = 'OpenBSD-6.7-amd64-install67.iso'
      else
        iso = 'OpenBSD-6.8-amd64-install68.iso'
      end

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
      when '20.04'
        iso = 'ubuntu-' + os_version + '-live-server-amd64.iso'
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

    # cloud-init enabled images can afford a config disk for the VM
    case os
    when 'freebsd'
      case os_version
      when '11.3','12.1','12.2'
        opt_params[:attach_config_disk] = true
      end
    when 'ubuntu'
      case os_version
      when '18.04','20.04'
        opt_params[:attach_config_disk] = true
      end
    when 'centos'
      case os_version
      when '8.1'
        opt_params[:attach_config_disk] = true
      end
    when 'debian'
      case os_version
      when '9.12','10.4'
        opt_params[:attach_config_disk] = true
      end
    when 'fedora'
      opt_params[:attach_config_disk] = true
    when 'opensuse_leap_jeos'
      opt_params[:attach_config_disk] = true
    when 'archlinux'
      opt_params[:attach_config_disk] = true
    when 'gentoo'
      opt_params[:attach_config_disk] = true
    when 'openbsd'
      case os_version
      when '6.7','6.8'
        opt_params[:attach_config_disk] = true
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

    if Rails.env == 'development'
      queue = Socket.gethostname
    else
      queue = vm.abbreviated_host
    end

    ARP_REDIS.lpush("queue:#{queue}", work.to_json)

    job
  end
end
