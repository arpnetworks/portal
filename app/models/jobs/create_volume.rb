class Jobs::CreateVolume < Job
  def perform(args_json)
    args = JSON.parse(args_json)

    vol_name = args['vol_name']
    host     = args['host']
    size     = args['size']
    opts     = args['opts'] || {}
    account_id = args['account_id']
    orig_args_json = args['orig_args_json']

    account = Account.find(account_id)

    job = super(account, orig_args_json || args_json, opts)

    template = opts['os_template']

    args = [job.id, job.jid,
            vol_name, size]

    opts_for_worker = {
      :ceph_pool => opts['ceph_pool']
    }

    if template
      work = {
        :class => 'CreateVolumeFromTemplateWorker',
        :args  => args + [template] + [opts_for_worker]
      }
    else
      work = {
        :class => 'CreateVolumeWorker',
        :args  => args + [opts_for_worker]
      }
    end

    work = work.merge({
      :jid   => job.jid,
      :retry => true,
      :enqueued_at => Time.now.to_f.to_s,
      :created_at  => Time.now.to_f.to_s
    })

    if Rails.env == 'development'
      queue = Socket.gethostname
    else
      queue = host.split('.').first
    end

    ARP_REDIS.lpush("queue:#{queue}", work.to_json)

    job
  end

  private

  def extract_ops(vm)
    opts = {}

    vm = VirtualMachine.find(vm['id'])

    # Explicit pool?  No problem
    if vm.pool && vm.pool.pool_type == 'RBD'
      opts.merge!(:ceph_pool => vm.pool_name)
    end

    opts
  end
end
