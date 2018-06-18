class Admin::IpBlocksController < Admin::HeadQuartersController
  before_filter :is_arp_admin?, :except => [:show]
  before_filter :is_arp_sub_admin?, :only => [:show]

  before_filter :find_ip_block, :only => [:show, :edit, :update, :destroy, :subnet, :swip, :swip_submit]
  before_filter :delete_empty_service_id, :only => [:create, :update]

  def index
    @ip_blocks = IpBlock.all.order("seq, ip_block_id, network")
  end

  def tree
    @ip_blocks = IpBlock.superblocks.includes(resource: [{ service: :account }])
  end

  def new
    if params[:ip_block]
      @ip_block = IpBlock.new(ip_block_params)
    else
      @ip_block = IpBlock.new
    end

    @ip_block.seq = 100 unless @ip_block.seq

    @include_blank = true
  end

  def create
    begin
      @ip_block = IpBlock.new(ip_block_params)

      if @ip_block.save
        flash[:notice] = "New IP block created"
        redirect_to tree_admin_ip_blocks_path and return
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
    @ip_blocks = [@ip_block]
    render :template => 'ip_blocks/show'
  end

  def update
    begin
      if @ip_block.update_attributes(ip_block_params)
        flash[:notice] = "Changes saved."
        redirect_to edit_admin_ip_block_path(@ip_block) and return
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
      @ip_block.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "There was an error deleting this record"
      flash[:error] += "<br/>"
      flash[:error] += e.message
    else
      flash[:notice] = 'IP block was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  def subnet
    @prefixlen = params[:prefixlen]
    @strategy  = params[:strategy]
    @limit     = params[:limit]

    @strategy  = 'leftmost' if @strategy.nil? || @strategy.empty?

    if @prefixlen
      @prefixlen = @prefixlen.sub(/^\/+/, '')
      @subnets_available = @ip_block.subnets_available(@prefixlen.to_i,
                                                       :Strategy => @strategy.to_sym,
                                                       :limit => @limit)
    end
  end

  def swip
    if @ip_block.cidr_obj.version == 6
      flash[:error] = "Sorry, IPv6 SWIP's are not supported at this time"
      redirect_to edit_admin_ip_block_path(@ip_block) and return
    end

    @form = OpenStruct.new
    @form.registration_action = "N"
    @form.network_name = @ip_block.arin_network_name
    @downstream_org = @ip_block.account
  end

  def swip_submit
    @form = OpenStruct.new(params[:form])
    @downstream_org = OpenStruct.new(params[:downstream_org])

    if @form.network_name == ""
      @form_error = "Network Name is required"
      render :action => 'swip' and return
    end
    # TODO: We should do more validation than this (almost all fields are
    # required by ARIN)

    Mailer.swip_reassign_simple(@form, @downstream_org, @ip_block).deliver_now
    flash[:notice] = "Submitted REASSIGN SIMPLE template to ARIN"

    redirect_to edit_admin_ip_block_path(@ip_block)
  end

  protected

  def find_ip_block
    @ip_block = IpBlock.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find IP block with ID #{params[:id]}"
    redirect_to(admin_ip_blocks_path)
  end

  def delete_empty_service_id
    service_id = params[:ip_block] && params[:ip_block][:service_id]
    if service_id && service_id.empty?
      params[:ip_block].delete(:service_id)
    end
  end

  private

  def ip_block_params
    params.require(:ip_block).permit(
      :service_id,
      :ip_block_id,
      :location_id,
      :cidr,
      :label,
      :vlan,
      :seq,
      :routed,
      :next_hop,
      :available,
      :notes
    )
  end
end
