class Admin::VlansController < Admin::HeadQuartersController
  before_action :verify_otp, only: %i[shutdown restore]

  # GET /admin_vlans
  # GET /admin_vlans.xml
  def index
    @vlans = Vlan.all.order('vlan')
    @vlans_array = @vlans.map(&:vlan)

    @vlans_from_ip_blocks = []
    @vlans_duplicate_filter = []
    IpBlock.all.each do |ip_block|
      next unless ip_block.vlan && !@vlans_array.include?(ip_block.vlan) &&
                  !@vlans_duplicate_filter.include?([ip_block.vlan, ip_block.location])

      @vlans_from_ip_blocks << Vlan.new(vlan: ip_block.vlan,
                                        label: "#{ip_block.account_name} #{ip_block.label}",
                                        location: ip_block.location)
      @vlans_duplicate_filter << [ip_block.vlan, ip_block.location]
    end

    @all_vlans = @vlans + @vlans_from_ip_blocks
    @all_vlans = @all_vlans.sort do |a, b|
      a.vlan.to_i <=> b.vlan.to_i
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @all_vlans }
    end
  end

  # GET /admin_vlans/1
  # GET /admin_vlans/1.xml
  def show
    @vlan = Vlan.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @vlan }
    end
  end

  # GET /admin_vlans/new
  # GET /admin_vlans/new.xml
  def new
    @vlan = Vlan.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @vlan }
    end
  end

  # GET /admin_vlans/1/edit
  def edit
    @vlan = Vlan.find(params[:id])
  end

  # POST /admin_vlans
  # POST /admin_vlans.xml
  def create
    @vlan = Vlan.new(vlan_params)

    respond_to do |format|
      if @vlan.save
        flash[:notice] = 'VLAN was successfully created.'
        format.html { redirect_to(admin_vlans_path) }
        format.xml  { render xml: @vlan, status: :created, location: @vlan }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @vlan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin_vlans/1
  # PUT /admin_vlans/1.xml
  def update
    @vlan = Vlan.find(params[:id])

    respond_to do |format|
      if @vlan.update(vlan_params)
        flash[:notice] = 'VLAN was successfully updated.'
        format.html { redirect_to(admin_vlans_path) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @vlan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_vlans/1
  # DELETE /admin_vlans/1.xml
  def destroy
    @vlan = Vlan.find(params[:id])

    begin
      @vlan.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'VLAN was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_vlans_url) }
      format.xml  { head :ok }
    end
  end

  def shutdown
    vlan_id = params[:id]
    location = params[:location] || VirtualMachine.find(params[:virtual_machine_id]).location.code

    flash[:notice] = "Sending shutdown command for VLAN #{vlan_id}"

    send_command('shutdown_vlan', vlan_id, location, params[:otp2])

    Vlan.mark_shutdown!(params[:virtual_machine_id], true)

    redirect_to(admin_virtual_machine_path(params[:virtual_machine_id]))
  end

  def restore
    vlan_id = params[:id]
    location = params[:location] || VirtualMachine.find(params[:virtual_machine_id]).location.code

    flash[:notice] = "Sending restore command for VLAN #{vlan_id}"

    send_command('restore_vlan', vlan_id, location, params[:otp2])

    Vlan.mark_shutdown!(params[:virtual_machine_id], false)

    redirect_to(admin_virtual_machine_path(params[:virtual_machine_id]))
  end

  protected

  def send_command(cmd, vlan_id, location, otp)
    Kernel.system('/usr/bin/ssh', '-o', 'ConnectTimeout=5', "#{$HOST_RANCID_USER}@#{$HOST_RANCID}",
                  otp, cmd, vlan_id.to_s, location)
  end

  private

  def vlan_params
    params.require(:vlan).permit(
      :vlan,
      :label,
      :location_id
    )
  end
end
