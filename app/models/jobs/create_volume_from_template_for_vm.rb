class Jobs::CreateVolumeFromTemplateForVM < Jobs::CreateVolume
  def perform(args_json)
    args = JSON.parse(args_json)

    vm   = args['vm']['virtual_machine']

    if vm.nil?
      vm = args['vm']
    end

    opts = args['opts'] || {}

    opts.merge!(extract_ops(vm))
    opts.merge!(:os_template => vm['os_template'])

    super({ :account_id => args['account_id'],
            :host       => vm['host'],
            :vol_name   => vm['label'],
            :size       => vm['storage'],
            :opts       => opts,
            :orig_args_json => args_json
          }.to_json)
  end
end
