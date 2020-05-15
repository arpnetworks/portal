class Admin::BgpSessionsPrefixesController < Admin::HeadQuartersController
  before_action :is_arp_admin?, except: [:show]
  before_action :is_arp_sub_admin?, only: [:show]
  before_action :find_bgp_sessions_prefix, only: %i[edit update destroy]

  # GET /admin_bgp_sessions_prefixes
  # GET /admin_bgp_sessions_prefixes.xml
  def index
    @bgp_sessions_prefixes = BgpSessionsPrefix.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @bgp_sessions_prefixes }
    end
  end

  # GET /admin_bgp_sessions_prefixes/new
  # GET /admin_bgp_sessions_prefixes/new.xml
  def new
    @bgp_sessions_prefix = BgpSessionsPrefix.new
    @include_blank = false

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @bgp_sessions_prefix }
    end
  end

  # GET /admin_bgp_sessions_prefixes/1/edit
  def edit
    @include_blank = true
  end

  # POST /admin_bgp_sessions_prefixes
  # POST /admin_bgp_sessions_prefixes.xml
  def create
    @bgp_sessions_prefix = BgpSessionsPrefix.new(bgp_sessions_prefix_params)

    respond_to do |format|
      if @bgp_sessions_prefix.save
        flash[:notice] = 'Prefix was successfully created.'
        format.html { redirect_to(admin_bgp_sessions_prefixes_path) }
        format.xml  { render xml: @bgp_sessions_prefix, status: :created, location: @bgp_sessions_prefix }
      else
        @include_blank = true
        format.html { render action: 'new' }
        format.xml  { render xml: @bgp_sessions_prefix.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @bgp_sessions_prefix.update(bgp_sessions_prefix_params)
        flash[:notice] = 'Prefix was successfully updated.'
        format.html { redirect_to(admin_bgp_sessions_prefixes_path) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @bgp_sessions_prefix.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_bgp_sessions_prefixes/1
  # DELETE /admin_bgp_sessions_prefixes/1.xml
  def destroy
    begin
      @bgp_sessions_prefix.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'Prefix was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_bgp_sessions_prefixes_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def find_bgp_sessions_prefix
    @bgp_sessions_prefix = BgpSessionsPrefix.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find prefix with ID #{params[:id]}"
    redirect_to(admin_bgp_sessions_prefixes_url)
  end

  private

  def bgp_sessions_prefix_params
    params.require(:bgp_sessions_prefix).permit(
      :bgp_session_id,
      :prefix,
      :prefixlen,
      :prefixlen_min,
      :prefixlen_max
    )
  end
end
