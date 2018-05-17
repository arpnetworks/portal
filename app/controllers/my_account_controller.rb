class MyAccountController < ProtectedController
  before_filter :default_params, :except => [:edit]

  def dashboard
    expiry = Account.tender_token_expiry_timestamp
    url_encoded_email = CGI::escape(@account.email)
    @tender_link = "http://support.arpnetworks.com/login?email=#{url_encoded_email}&expires=#{expiry}&hash=#{@account.tender_token(expiry)}"
    @services = @account.services.active

    # If we wanted all unpaid invoices to appear on top
    # @invoices = @account.invoices.active.find(:all, :order => 'paid asc, date desc', :limit => 5)

    @invoices = @account.invoices.active.order('date desc').limit(5)
    @unpaid_invoices = @account.invoices_unpaid
    @enable_summary_view = true

    @jobs = @account.jobs.recent.order('created_at desc').limit(5)
  end

  protected

  def default_params
    @account  = Account.find(session[:account_id])
    @per_page = (params[:per_page] ||= 10).to_i
  end
end
