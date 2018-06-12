class Admin::BackupQuotasController < Admin::HeadQuartersController
  before_filter :find_backup_quota, :only => [:edit, :update, :destroy]

  # GET /admin_backup_quotas
  # GET /admin_backup_quotas.xml
  def index
    @backup_quotas = BackupQuota.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @all_backup_quotas }
    end
  end

  # GET /admin_backup_quotas/new
  # GET /admin_backup_quotas/new.xml
  def new
    @backup_quota = BackupQuota.new
    @include_blank = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @backup_quota }
    end
  end

  # GET /admin_backup_quotas/1/edit
  def edit
    @include_blank = true
  end

  # POST /admin_backup_quotas
  # POST /admin_backup_quotas.xml
  def create
    @backup_quota = BackupQuota.new(backup_quota_params)

    respond_to do |format|
      if @backup_quota.save
        flash[:notice] = 'Backup quota was successfully created.'
        format.html { redirect_to(admin_backup_quotas_path) }
        format.xml  { render :xml => @backup_quota, :status => :created, :location => @backup_quota }
      else
        @include_blank = true
        format.html { render :action => "new" }
        format.xml  { render :xml => @backup_quota.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin_backup_quotas/1
  # PUT /admin_backup_quotas/1.xml
  def update
    respond_to do |format|
      if @backup_quota.update_attributes(backup_quota_params)
        flash[:notice] = 'Backup quota was successfully updated.'
        format.html { redirect_to(admin_backup_quotas_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @backup_quota.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_backup_quotas/1
  # DELETE /admin_backup_quotas/1.xml
  def destroy
    begin
      @backup_quota.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = "There was an error deleting this record"
      flash[:error] += "<br/>"
      flash[:error] += e.message
    else
      flash[:notice] = 'Backup quota was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_backup_quotas_url) }
      format.xml  { head :ok }
    end
  end

  protected

  def find_backup_quota
    @backup_quota = BackupQuota.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find backup quota with ID #{params[:id]}"
    redirect_to(admin_backup_quotas_url)
  end

  private

  def backup_quota_params
    params.require(:backup_quota).permit(
      :service_id,
      :server,
      :username,
      :quota,
      :notes
    )
  end

end
