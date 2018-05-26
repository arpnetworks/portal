module BandwidthQuotasHelper
  def bandwidth_quotas_colspan(admin, action_name)
    if admin && action_name == 'index'
      6
    else
      5
    end
  end

  def bandwidth_quotas_table_onClick(bandwidth_quota)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? edit_admin_bandwidth_quota_path(bandwidth_quota.id) : account_service_bandwidth_quotas_path(@account, @service, bandwidth_quota.id))
      html << "'\"".html_safe
    end
  end
end
