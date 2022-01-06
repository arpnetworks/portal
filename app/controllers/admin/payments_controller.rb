class Admin::PaymentsController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only:   [:show]
  before_action :find_invoice,      only: %i[new show edit update destroy]
  before_action :find_payment,      only: %i[show edit update destroy]


  def index
    @payments = Payment.paginate(page: params[:page],
                                 per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def show; end

  def new
    @payment = @invoice.payments.new
    @payment.date = Date.today

    render layout: 'responsive'
  end

  protected

  def find_invoice
    begin
      @invoice = Invoice.find(params[:invoice_id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Could not find invoice with ID #{params[:invoice_id]}"
    end
  end

  def find_payment
    begin
      @payment = @invoice.payments.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] =
        "Could not find payment with ID #{params[:id]} corresponding to invoice with ID #{params[:invoice_id]}"
      redirect_to(admin_invoices_path)
    end
  end
end
