class Admin::PaymentsController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only:   [:show]
  before_action :find_invoice,      only: %i[create new show edit update destroy]
  before_action :find_payment,      only: %i[show edit update destroy]

  def index
    # @payments = Payment.paginate(page: params[:page],
                                 # per_page: params[:per_page] || 20).order('created_at DESC')
    redirect_to admin_invoice_path(params[:invoice_id])
  end

  def show; end

  def new
    @payment = @invoice.payments.new
    @payment.date = Date.today

    render layout: 'responsive'
  end

  def create
    @payment = @invoice.payments.new(payment_params)
    @payment.account_id = @invoice.account_id

    if @payment.save!
      @invoice.payments << @payment

      # This should really go in the model
      if @invoice.balance == 0
        @invoice.paid = true
        @invoice.save
      end

      flash[:notice] = 'New payment saved'
      redirect_to(admin_invoice_path(@invoice)) and return
    end
  rescue ActiveRecord::RecordInvalid => e
    render action: 'new', layout: 'responsive'
  end

  protected

  def find_invoice
    @invoice = Invoice.find(params[:invoice_id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find invoice with ID #{params[:invoice_id]}"
    redirect_to(admin_invoices_path)
  end

  def find_payment
    @payment = @invoice.payments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] =
      "Could not find payment with ID #{params[:id]} corresponding to invoice with ID #{params[:invoice_id]}"
    redirect_to(admin_invoices_path)
  end

  private

  def payment_params
    params.require(:payment).permit(
      :date,
      :reference_number,
      :check_number,
      :method,
      :amount,
      :notes
    )
  end
end
