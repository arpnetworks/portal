class Admin::ServicesController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only: [:show]
  before_action :find_service,      only: %i[show edit update destroy push_to_stripe pull_from_stripe]
  before_action :push_pull_stripe_gate, only: %i[push_to_stripe pull_from_stripe]

  def index
    @services = Service.paginate(page: params[:page],
                                 per_page: params[:per_page]).order('created_at DESC')

    @services_active = Service.active.all
    @service_totals = Service.give_me_totals(@services_active).sort
  end

  def dangling
    @services = StripeService.dangling.paginate(page: params[:page],
                                                per_page: params[:per_page]).order('created_at DESC')

    render 'index'
  end

  def new
    @service = Service.new
    @include_blank = true
  end

  def create
    begin
      @service = Service.new(service_params)

      if @service.save
        flash[:notice] = 'New service created'
        redirect_to(admin_services_path) && return
      end
    rescue ActiveRecord::StatementInvalid => e
      flash.now[:error] = 'There was an error creating this record'
      flash.now[:error] += '<br/>'
      flash.now[:error] += e.message
    end

    @include_blank = true
    render action: 'new'
  end

  def edit; end

  def show
    @services = [@service]
    @description = @service.description || ''

    instantiate_resources_of_service(@service)

    # If no IP blocks are associated with this service, find the first service
    # with code of IP_BLOCK and use it instead.  For now, this is solely used
    # by the Provisioning Helper.
    if @ip_blocks.empty?
      sc_id = (o = ServiceCode.find_by(name: 'IP_BLOCK')) && o.id
      @ip_block_service = @service.account.services.find_by(service_code_id: sc_id, deleted_at: nil)
    end

    # This is used soley for the Reverse DNS Helper
    unless @ip_blocks.empty?
      @ns = params[:ns] || []
      @ns_arg = @ns.map do |ns|
        ns.empty? ? nil : ns
      end
      @ns_arg.compact!

      @ipv4_blocks = @ip_blocks.map do |ip_block|
        ip_block.version == 4 ? ip_block : nil
      end
      @ipv4_blocks.compact!
    end

    @iso_files = iso_files if @service.service_code.name == 'VPS'

    render template: 'services/show'
  end

  def update
    begin
      if @service.update(service_params)
        flash[:notice] = 'Changes saved.'
        redirect_to(last_location) && return
      end
    rescue ActiveRecord::StatementInvalid => e
      flash.now[:error] = 'There was an error updating this record'
      flash.now[:error] += '<br/>'
      flash.now[:error] += e.message
    end

    render action: 'edit'
  end

  def destroy
    begin
      @service.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'Service was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  def push_to_stripe
    # Set pending back to true in order to force activation again
    @service.pending = true
    @service.activate_billing!

    flash[:notice] = 'Service pushed to Stripe.'

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  def pull_from_stripe
    stripe_subscription = @service.account.stripe_subscription
    stripe_subscription.set_subscription_item_id!(@service)

    if @service.stripe_subscription_item_id.blank?
      flash[:error] = 'Couldn\'t find Subscription Item ID from Stripe.'
    else
      flash[:notice] = 'Subscription Item ID pulled from Stripe.'
    end

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  protected

  def find_service
    @service = Service.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find service with ID #{params[:id]}"
    redirect_to(admin_services_path)
  end

  def push_pull_stripe_gate
    unless @service.account.offload_billing?
      flash[:error] = "This account hasn't been set up completely in Stripe, aborting..."
      redirect_to(last_location) && return
    end

    if @service.stripe_price_id.blank?
      flash[:error] = 'No Price ID provided, aborting...'
      redirect_to(last_location) && return
    end

    if @service.stripe_subscription_item_id.present?
      flash[:error] = 'SubscriptionItem ID is already set, refusing to push/pull again, aborting...'
      redirect_to(last_location) && return
    end
  end

  private

  def service_params
    params.require(:service).permit(
      :account_id,
      :service_code_id,
      :title,
      :description,
      :billing_interval,
      :billing_amount,
      :billing_due_on,
      :date_start,
      :date_end,
      :label,
      :coupon,
      :pending,
      :stripe_price_id,
      :stripe_subscription_item_id,
      :stripe_quantity
    )
  end
end
