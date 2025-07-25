class Admin::InvoicesController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only:   [:show]
  before_action :find_invoice,      only: %i[show edit update destroy mark_paid mark_unpaid duplicate]

  def index
    @invoices = Invoice.paginate(page: params[:page],
                                 per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def show
    render template: 'invoices/show', layout: 'responsive'
  end

  def new
    @invoice = Invoice.new
    @invoice.date = Date.today
    @invoice.line_items.build  # Build at least one empty line item for new invoices
    @service_codes = ServiceCode.all.pluck(:name)
    render 'form', layout: 'responsive'
  end

  def create
    normalize_blank_amounts
    @invoice = Invoice.new(invoice_params)
    
    # If bill_to is blank on a new invoice, set it to nil so the model callback can auto-assign it
    if @invoice.bill_to.blank?
      @invoice.bill_to = nil
    end
    
    if @invoice.save
      flash[:notice] = "Invoice ##{@invoice.id} was created."
      redirect_to admin_invoice_path(@invoice)
    else
      @service_codes = ServiceCode.all.pluck(:name)
      render 'form', layout: 'responsive'
    end
  end

  def edit
    @service_codes = ServiceCode.all.pluck(:name)
    render 'form', layout: 'responsive'
  end

  def update
    normalize_blank_amounts
    
    if @invoice.update(invoice_params)
      flash[:notice] = "Invoice ##{@invoice.id} was updated."
      redirect_to admin_invoice_path(@invoice)
    else
      @service_codes = ServiceCode.all.pluck(:name)
      render 'form', layout: 'responsive'
    end
  end

  def destroy
    if @invoice.paid?
      flash[:error] = 'Cannot delete a paid invoice'
      redirect_to(last_location) && return
    end

    begin
      @invoice.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = "Invoice ##{@invoice.id} was deleted."
    end

    respond_to do |format|
      format.html { redirect_to(last_location) }
      format.xml  { head :ok }
    end
  end

  def mark_paid
    @invoice.paid = true
    @invoice.save

    flash[:notice] = "Invoice ##{@invoice.id} marked paid."

    redirect_to admin_invoice_path @invoice
  end

  def mark_unpaid
    @invoice.paid = false
    @invoice.save

    flash[:notice] = "Invoice ##{@invoice.id} marked unpaid."

    redirect_to admin_invoice_path @invoice
  end

  def duplicate
    # Create a new invoice with the same attributes
    new_invoice = @invoice.dup
    new_invoice.pending = true
    new_invoice.paid = false
    new_invoice.date = Date.today
    
    if new_invoice.save
      # Duplicate all line items
      @invoice.line_items.each do |line_item|
        new_line_item = line_item.dup
        new_line_item.invoice_id = new_invoice.id
        new_line_item.date = Date.today
        new_line_item.save
      end
      
      flash[:notice] = "Invoice duplicated successfully. This is a pending invoice that won't be visible to the customer until published."
      redirect_to edit_admin_invoice_path(new_invoice)
    else
      flash[:error] = "Failed to duplicate invoice."
      redirect_to admin_invoice_path(@invoice)
    end
  end

  protected

  def find_invoice
    @invoice = Invoice.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find invoice with ID #{params[:id]}"
    redirect_to(admin_invoices_path)
  end

  private

  def invoice_params
    params.require(:invoice).permit(
      :account_id, :date, :terms, :bill_to, :message, :pending, :archived,
      line_items_attributes: [:id, :date, :code, :description, :amount, :_destroy]
    )
  end

  def normalize_blank_amounts
    if params[:invoice][:line_items_attributes]
      params[:invoice][:line_items_attributes].each do |key, line_item_attrs|
        if line_item_attrs[:amount].blank?
          line_item_attrs[:amount] = "0"
        end
      end
    end
  end
end
