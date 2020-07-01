class Admin::ServiceCodesController < Admin::HeadQuartersController
  before_action :is_arp_admin?, except: [:show]
  before_action :is_arp_sub_admin?, only: [:show]

  # GET /admin_service_codes
  # GET /admin_service_codes.xml
  def index
    @service_codes = ServiceCode.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @service_codes }
    end
  end

  # GET /admin_service_codes/1
  # GET /admin_service_codes/1.xml
  def show
    @service_code = ServiceCode.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @service_code }
    end
  end

  # GET /admin_service_codes/new
  # GET /admin_service_codes/new.xml
  def new
    @service_code = ServiceCode.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @service_code }
    end
  end

  # GET /admin_service_codes/1/edit
  def edit
    @service_code = ServiceCode.find(params[:id])
  end

  # POST /admin_service_codes
  # POST /admin_service_codes.xml
  def create
    @service_code = ServiceCode.new(service_code_params)

    respond_to do |format|
      if @service_code.save
        flash[:notice] = 'Service Code was successfully created.'
        format.html { redirect_to(admin_service_codes_path) }
        format.xml  { render xml: @service_code, status: :created, location: @service_code }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @service_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /admin_service_codes/1
  # PUT /admin_service_codes/1.xml
  def update
    @service_code = ServiceCode.find(params[:id])

    respond_to do |format|
      if @service_code.update(service_code_params)
        flash[:notice] = 'ServiceCode was successfully updated.'
        format.html { redirect_to(admin_service_codes_path) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @service_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_service_codes/1
  # DELETE /admin_service_codes/1.xml
  def destroy
    @service_code = ServiceCode.find(params[:id])

    begin
      @service_code.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'Service Code was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(admin_service_codes_url) }
      format.xml  { head :ok }
    end
  end

  private

  def service_code_params
    params.require(:service_code).permit(:name)
  end
end
