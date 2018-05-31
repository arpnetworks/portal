class Admin::BandwidthQuotasController < Admin::HeadQuartersController
  before_filter :is_arp_admin?, :except => [:show]
  before_filter :is_arp_sub_admin?, :only => [:show]
  before_filter :find_bandwidth_quota, :only => [:edit, :update, :destroy]

  # GET /admin_bandwidth_quotas
  # GET /admin_bandwidth_quotas.xml
  def index
    @bandwidth_quotas = BandwidthQuota.paginate(page:     params[:page],
                                       per_page: params[:per_page] || 20).order('created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @all_bandwidth_quotas }
    end
  end

  # GET /admin_bandwidth_quotas/new
  # GET /admin_bandwidth_quotas/new.xml
  def new
    @bandwidth_quota = BandwidthQuota.new
    @include_blank = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bandwidth_quota }
    end
  end

  # GET /admin_bandwidth_quotas/1/edit
  def edit
    @include_blank = true
  end

  # POST /admin_bandwidth_quotas
  # POST /admin_bandwidth_quotas.xml
  def create
    @bandwidth_quota = BandwidthQuota.new(params[:bandwidth_quota])

    respond_to do |format|
      if @bandwidth_quota.save
        flash[:notice] = 'Bandwidth quota was successfully created.'
        format.html { redirect_to(admin_bandwidth_quotas_path) }
        format.xml  { render :xml => @bandwidth_quota, :status => :created, :location => @bandwidth_quota }
      else
        @include_blank = true
        format.html { render :action => "new" }
        format.xml  { render :xml => @bandwidth_quota.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_bandwidth_quotas/1
  # PUT /admin_bandwidth_quotas/1.xml
  def update
    respond_to do |format|
      if @bandwidth_quota.update_attributes(bandwidth_quota_params)
        flash[:notice] = 'Bandwidth quota was successfully updated.'
        format.html { redirect_to(admin_bandwidth_quotas_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bandwidth_quota.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_bandwidth_quotas/1
  # DELETE /admin_bandwidth_quotas/1.xml
  def destroy
    begin
      @bandwidth_quota.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "There was an error deleting this record"
      flash[:error] += "<br/>"
      flash[:error] += e.message
    else
      flash[:notice] = 'Bandwidth quota was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_bandwidth_quotas_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def find_bandwidth_quota
    @bandwidth_quota = BandwidthQuota.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find bandwidth quota with ID #{params[:id]}"
    redirect_to(admin_bandwidth_quotas_url)
  end

  private

  def bandwidth_quota_params
    params.require(:bandwidth_quota).permit(
      :commit,
      :commit_unit,
      :commit_overage,
      :cacti_username,
      :cacti_password,
      :cacti_local_graph_id,
      :notes
    )
  end
end
