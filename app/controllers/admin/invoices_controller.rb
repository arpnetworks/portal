class Admin::InvoicesController < Admin::HeadQuartersController
  before_action :is_arp_admin?,     except: [:show]
  before_action :is_arp_sub_admin?, only:   [:show]
  before_action :find_invoice,      only: %i[show destroy]

  def index
    @invoices = Invoice.paginate(page: params[:page],
                                 per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def show
    render template: 'invoices/show'
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

  protected

  def find_invoice
    @invoice = Invoice.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find invoice with ID #{params[:id]}"
    redirect_to(admin_invoices_path)
  end
end
