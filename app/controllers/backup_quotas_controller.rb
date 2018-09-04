class BackupQuotasController < ProtectedController
  def ssh_key
    @target   = @account.find_backup_quota_by_id(params[:id])
    @service  = Service.find(params[:service_id])
    @item     = 'Backup Space'
    @route    = 'backup_quota'

    render '/virtual_machines/ssh_key', :layout => true
  end

  def ssh_key_post
    keys = params[:keys].strip

    if keys.empty?
      flash[:error] = "Your submission was empty"
      redirect_to ssh_key_account_service_backup_quota_path(params[:account_id],
                                                            params[:service_id],
                                                            params[:id])
      return
    end

    bq = @account.find_backup_quota_by_id(params[:id])

    append = false
    keys.split("\n").each do |key|
      ssh_key_send(bq.server, bq.username, key, append, bq.quota)
      append = true
    end

    flash[:notice] = "Your SSH key(s) have been received and installed.  Thank you!"
    redirect_to ssh_key_account_service_backup_quota_path(params[:account_id],
                                                          params[:service_id],
                                                          params[:id])
  end

  private

  def ssh_key_send(server, login, key, append, quota)
    # Send the key to server
    Kernel.system("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$KEYER}@#{server}", "add",
                  append ? '1' : '0', login, quota, key)

    simple_email("SSH Key Submission for Backup Server", command) rescue nil
  end
end
