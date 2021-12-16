class Admin::StripeEventsController < Admin::HeadQuartersController
  before_action :is_arp_admin?
  before_action :find_stripe_event, only: %i[show edit update destroy retry]

  def index
    @stripe_events = StripeEvent.paginate(page: params[:page],
                                           per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def destroy
    begin
      @stripe_event.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = "StripeEvent #{@stripe_event.id} was deleted."
    end

    respond_to do |format|
      format.html { redirect_to admin_stripe_events_path }
      format.xml  { head :ok }
    end
  end

  def retry
    begin
      @stripe_event.go!
    rescue StandardError => e
      flash[:error] = e.message
    else
      flash[:notice] = "Retried processing Stripe Event #{@stripe_event.id}"
    end

    respond_to do |format|
      format.html { redirect_to admin_stripe_events_path }
      format.xml  { head :ok }
    end
  end

  protected

  def find_stripe_event
    @stripe_event = StripeEvent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find StripeEvent with ID #{params[:id]}"
    redirect_to(admin_stripe_events_path)
  end
end
