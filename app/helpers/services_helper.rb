module ServicesHelper
  def services_colspan(admin)
    admin ? 6 : 5
  end

  def instantiate_resource(resource)
    case resource.assignable_type
    when 'VirtualMachine'
      @virtual_machine = resource.assignable 
      @virtual_machines = @virtual_machine ? [@virtual_machine] : []
    when 'BandwidthQuota'
      @bandwidth_quota = resource.assignable
      @bandwidth_quotas = @bandwidth_quota ? [@bandwidth_quota] : []
    when 'BackupQuota'
      @backup_quota = resource.assignable
      @backup_quotas = @backup_quota ? [@backup_quota] : []
    when 'BgpSession'
      @bgp_session = resource.assignable
      @bgp_sessions = @bgp_session ? [@bgp_session] : []
    when 'BgpSessionsPrefix'
      @bgp_sessions_prefix = resource.assignable
      @bgp_sessions_prefixes = @bgp_sessions_prefix ? [@bgp_sessions_prefix] : []
    end
  end
end
