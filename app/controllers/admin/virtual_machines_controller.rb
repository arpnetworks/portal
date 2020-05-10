class Admin::VirtualMachinesController < Admin::HeadQuartersController
  before_filter :is_arp_admin?,     :except => [:show]
  before_filter :is_arp_sub_admin?, :only => [:show]
  before_filter :find_virtual_machine,
    :only => [:show, :edit, :update, :destroy, :monitoring_reminder_post]

  def index
    @virtual_machines = VirtualMachine.paginate(:page => params[:page],
                                                :per_page => params[:per_page]).order('created_at DESC')
  end

  def new
    @virtual_machine = VirtualMachine.new
    @include_blank = true
  end

  def create
    begin
      @virtual_machine = VirtualMachine.new(virtual_machine_params)

      if @virtual_machine.save

        # These must be set after the fact b/c virtual_machines_interfaces is
        # not created until after the virtual_machine record is created
        [:mac_address,
         :ip_address,
         :ip_netmask,
         :ipv6_address,
         :ipv6_prefixlen].each do |attrib|
          @virtual_machine.send("#{attrib}=", params[:virtual_machine][attrib])
        end

        flash[:notice] = "New virtual machine created"
        redirect_to admin_virtual_machines_path and return
      end
    rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound => e
      flash.now[:error] = "There was an error creating this record"
      flash.now[:error] += "<br/>"
      flash.now[:error] += e.message

      @service = nil
    end

    @include_blank = true
    render :action => 'new'
  end

  def edit
    @include_blank = true
  end

  def show
    @virtual_machines = [@virtual_machine]
    render :template => 'virtual_machines/show'
  end

  def update
    begin
      # Old attributes
      old_ram = @virtual_machine.ram

      # Deal with non-existent virtual_machines_interfaces
      vm_interfaces = @virtual_machine.virtual_machines_interfaces
      vm_interfaces.size == 0 && vm_interfaces.create

      if @virtual_machine.update_attributes(virtual_machine_params)
        flash[:notice] = "Changes saved."

        # New attributes
        new_ram = @virtual_machine.ram

        if !params[:otp].blank?
          if verify_otp
            if old_ram != new_ram
              new_ram = new_ram * 1024
              write_request(@virtual_machine, "set-param", "ram #{new_ram}")

              Mailer.simple_notification("VM: #{@virtual_machine.UUID} RAM changed from #{old_ram} to #{new_ram}", "").deliver_now
            end
          else
            return
          end
        end

        redirect_to last_location and return
      end
    rescue ActiveRecord::StatementInvalid => e
      flash.now[:error] = "There was an error updating this record"
      flash.now[:error] += "<br/>"
      flash.now[:error] += e.message
    end

    render :action => 'edit'
  end

  def destroy
    begin
      @virtual_machine.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "There was an error deleting this record"
      flash[:error] += "<br/>"
      flash[:error] += e.message
    else
      flash[:notice] = 'Virtual Machine was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  def monitoring_reminder_post
    Mailer.vps_monitoring_reminder(@virtual_machine).deliver_now
    flash[:notice] = "VPS monitoring reminder sent"

    redirect_to admin_virtual_machine_path(@virtual_machine)
  end

  protected

  def find_virtual_machine
    begin
      # Have we been provided with a UUID instead of numeric ID?
      if params[:id] =~ /\w{8,8}-\w{4,4}-\w{4,4}-\w{4,4}-\w{12,12}/
        @virtual_machine = VirtualMachine.find_by_uuid(params[:id])
      else
        @virtual_machine = VirtualMachine.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Could not find virtual machine with ID #{params[:id]}"
      redirect_to(admin_virtual_machines_path)
    end
  end

  private

  def virtual_machine_params
    params.require(:virtual_machine).permit(
      :uuid,
      :os,
      :ram,
      :storage,
      :pool_id,
      :notes,
      :console_login,
      :conserver_password,
      :host,
      :vnc_port,
      :vnc_password,
      :label,
      :os_template,
      :websocket_port,
      :serial_port,
      :mac_address,
      :ip_address,
      :ip_netmask,
      :ipv6_address,
      :ipv6_prefixlen
    )
  end
end
