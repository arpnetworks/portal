module BackupQuotasHelper
  def backup_quotas_colspan(admin)
    admin ? 5 : 4
  end

  def backup_quotas_table_onClick(backup_quota)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? edit_admin_backup_quota_path(backup_quota.id) : account_service_backup_quotas_path(@account, @service, backup_quota.id))
      html << "'\"".html_safe
    end
  end

  def backup_quotas_format(quota)
    (quota / 1000 / 1000).to_s + " GB"
  end
end
