class VirtualMachinesController < ProtectedController
  def boot
    vm = @account.find_virtual_machine_by_id(params[:id])

    if vm
      vm.change_state!('start')

      flash[:notice_for_vm] = "Request to boot VM has been sent, please allow 5 - 10 seconds for this request to be processed."
    end

    respond_to do |format|
      format.html do
        if request.env["HTTP_REFERER"] =~ Regexp.new('/admin/')
          redirect_to admin_virtual_machine_path(params[:id])
        else
          redirect_to account_service_path(params[:account_id],
                                           params[:service_id])
        end
      end
    end
  end

  def shutdown
    vm = @account.find_virtual_machine_by_id(params[:id])

    if vm
      vm.change_state!('shutdown')

      flash[:notice_for_vm] = "Request to gracefully shutdown VM has been sent, please allow 5 - 10 seconds for this request to be processed."
    end

    respond_to do |format|
      format.html do
        redirect_to account_service_path(params[:account_id],
                                         params[:service_id])
      end
    end
  end

  def shutdown_hard
    vm = @account.find_virtual_machine_by_id(params[:id])

    if vm
      vm.change_state!('destroy')

      flash[:notice_for_vm] = "Request to forcefully shutdown VM has been sent, please allow 5 - 10 seconds for this request to be processed."
    end

    respond_to do |format|
      format.html do
        redirect_to account_service_path(params[:account_id],
                                         params[:service_id])
      end
    end
  end

  def iso_change
    @iso_files = iso_files
    @iso_file  = params[:iso_file]

    vm = @account.find_virtual_machine_by_id(params[:id])

    if vm
      if @iso_files.member?(@iso_file)
        if vm.host =~ /[ks]ct/
          # Our new way, based on Redis
          vm.set_iso!(@iso_file)
        else
          vm.set_iso!("#{$ISO_BASE}/#{@iso_file}", legacy: true)
        end

        flash[:notice_for_vm_iso] = "Request to change CD-ROM ISO has been sent, please allow 5 - 10 seconds for this request to be processed."

        Mailer.simple_notification("ISO: #{@account.display_account_name} changed ISO to #{@iso_file}", nil).deliver_now
      else
        Mailer.simple_notification("ISO: ** --> Possible attempt to manipulate ISO filename <-- **",
                                   @account.display_account_name).deliver_now
      end
    end

    respond_to do |format|
      format.html do
        redirect_to account_service_path(params[:account_id],
                                         params[:service_id])
      end
    end
  end

  def advanced_parameter
    @parameter = params[:advanced_parameter]

    if @parameter
      @param, @value = @parameter.split('_')

      @vm = @account.find_virtual_machine_by_id(params[:id])
      @vm.set_advanced_parameter!(@param, @value)

      flash[:notice] = "Request to change advanced parameter has been sent, please allow 5 - 10 seconds for this request to be processed."
      Mailer.simple_notification("ADV Param: #{@account.display_account_name} changed #{@param} to #{@value}", nil).deliver_now
    end

    respond_to do |format|
      format.html do
        redirect_to account_service_path(params[:account_id],
                                         params[:service_id])
      end
    end
  end

  def console
    @vm = @account.find_virtual_machine_by_id(params[:id])

    if @vm
      render '/virtual_machines/console', :layout => false
    else
      redirect_to :dashboard
    end
  end

  def ssh_key
    @target   = @account.find_virtual_machine_by_id(params[:id])
    @service  = Service.find(params[:service_id])
    @item     = 'Virtual Machine'
    @route    = 'virtual_machine'
  end

  def ssh_key_post
    keys = params[:keys].strip

    if keys.empty?
      flash[:error] = "Your submission was empty"
      redirect_to ssh_key_account_service_virtual_machine_path(params[:account_id],
                                                               params[:service_id],
                                                               params[:id])
      return
    end

    vm = @account.find_virtual_machine_by_id(params[:id])

    append = false
    keys.split("\n").each do |key|
      ssh_key_send(vm.console_login, key, append)
      append = true
    end

    flash[:notice] = "Your SSH key(s) have been received and installed.  Thank you!"
    redirect_to ssh_key_account_service_virtual_machine_path(params[:account_id],
                                                             params[:service_id],
                                                             params[:id])
  end

  private

  def ssh_key_send(login, key, append)
    Kernel.system("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$KEYER}@#{$HOST_CONSOLE}", "add",
                  append ? '1' : '0', login, key)

    Mailer.simple_notification('SSH Key Submission', "add " + (append ? 1 : 0).to_s + " #{login} #{key}").deliver_now
  end
end
