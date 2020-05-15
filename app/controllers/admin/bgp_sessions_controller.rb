class Admin::BgpSessionsController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only:   [:show]
  before_action :find_bgp_session,  only:   %i[edit update destroy]

  # GET /admin_bgp_sessions
  # GET /admin_bgp_sessions.xml
  def index
    @bgp_sessions = BgpSession.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @all_bgp_sessions }
    end
  end

  # GET /admin_bgp_sessions/new
  # GET /admin_bgp_sessions/new.xml
  def new
    @bgp_session = BgpSession.new
    @include_blank = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @bgp_session }
    end
  end

  # GET /admin_bgp_sessions/1/edit
  def edit
    @include_blank = false

    @ips_for_rpf_filter = []
    @rpf_vlan = @rpf_filter = ''
    @account = @bgp_session.account

    if @bgp_session.peer_host =~ /s1\.lax/
      if @account
        @ip_blocks = @account.ip_blocks

        @ip_blocks = @ip_blocks.select do |ip_block|
          ip_block.version == 4 &&
            ip_block.location == Location.find_by(code: 'lax')
        end

        @ips_for_rpf_filter = @ip_blocks
        @ips_for_rpf_filter_without_session_prefixes = @ip_blocks

        unless @ips_for_rpf_filter.empty?
          @rpf_vlan = @ips_for_rpf_filter.first.vlan

          @ips_for_rpf_filter = \
            @ips_for_rpf_filter_without_session_prefixes = @ips_for_rpf_filter.map(&:cidr_obj)

          @ips_for_rpf_filter += @bgp_session.prefixes.map do |prefix|
            NetAddr::CIDR.create(prefix.prefix)
          end

          @rpf_filter = 'rpf-vl' + @rpf_vlan.to_s
        end
      end
    end
  end

  # POST /admin_bgp_sessions
  # POST /admin_bgp_sessions.xml
  def create
    @bgp_session = BgpSession.new(bgp_session_params)

    respond_to do |format|
      if @bgp_session.save
        flash[:notice] = 'BGP session was successfully created.'
        format.html { redirect_to(admin_bgp_sessions_path) }
        format.xml  { render xml: @bgp_session, status: :created, location: @bgp_session }
      else
        @include_blank = true
        format.html { render action: 'new' }
        format.xml  { render xml: @bgp_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin_bgp_sessions/1
  # PUT /admin_bgp_sessions/1.xml
  def update
    respond_to do |format|
      if @bgp_session.update(bgp_session_params)
        flash[:notice] = 'BGP session was successfully updated.'
        format.html { redirect_to(admin_bgp_sessions_path) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @bgp_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_bgp_sessions/1
  # DELETE /admin_bgp_sessions/1.xml
  def destroy
    begin
      @bgp_session.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'BGP session was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_bgp_sessions_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def find_bgp_session
    @bgp_session = BgpSession.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find BGP session with ID #{params[:id]}"
    redirect_to(admin_bgp_sessions_url)
  end

  private

  def bgp_session_params
    params.require(:bgp_session).permit(
      :service_id,
      :asn,
      :peer_host,
      :peer_ip_address_a,
      :peer_ip_address_z,
      :multihop,
      :as_set
    )
  end
end
