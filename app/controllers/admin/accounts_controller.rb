class Admin::AccountsController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only: [:show]
  before_action :find_account,      only: %i[show edit update destroy]

  def index
    @accounts = Account.paginate(page: params[:page],
                                 per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def suspended
    @accounts = Account.suspended.paginate(page: params[:page],
                                           per_page: params[:per_page] || 20).order('created_at DESC')

    render action: 'index'
  end

  def new
    @account = Account.new
    @include_blank = true
  end

  def create
    begin
      @account = Account.new(account_params)

      # This field is protected from mass assignment
      @account.login = params[:account][:login]

      if @account.save
        flash[:notice] = 'New account created'
        redirect_to(admin_accounts_path) && return
      end
    rescue ActiveRecord::StatementInvalid => e
      flash.now[:error] = 'There was an error creating this record'
      flash.now[:error] += '<br/>'
      flash.now[:error] += e.message
    end

    @include_blank = true
    render action: 'new'
  end

  def edit
    # Don't show password on form
    @account.password              = ''
    @account.password_confirmation = ''
  end

  def show
    @accounts = [@account]
    @services = @enable_admin_view ? @account.services : @account.services.active

    @invoices = if @enable_admin_view
                  @account.invoices.all.order('date desc')
                else
                  @account.invoices.active.order('date desc')
                end

    @mrc = @account.services.active.inject(0) { |sum, o| o.billing_interval == 1 ? sum + o.billing_amount : sum + 0 }
  end

  def update
    begin
      # This field is protected from mass assignment
      @account.login = params[:account][:login]

      # If no new password was provided, remove it from params so we don't save
      # a blank password.
      if params[:account][:password] == ''
        params[:account].delete(:password)
        params[:account].delete(:password_confirmation)
      end

      if @account.update(account_params)
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
      @account.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = 'Account was deleted.'
    end

    respond_to do |format|
      format.html { redirect_to last_location }
      format.xml  { head :ok }
    end
  end

  protected

  def find_account
    @account = Account.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find account with ID #{params[:id]}"
    redirect_to(admin_accounts_path)
  end

  private

  def account_params
    params.require(:account).permit(
      :login,
      :email,
      :email2,
      :email_billing,
      :password,
      :password_confirmation,
      :company,
      :first_name,
      :last_name,
      :address1,
      :address2,
      :city,
      :state,
      :zip,
      :country,
      :stripe_customer_id,
      :stripe_payment_method_id
    )
  end
end
