class Admin::InvoicesController < Admin::HeadQuartersController
  before_filter :is_arp_admin?,     except: [:show]
  before_filter :is_arp_sub_admin?, only:   [:show]

  def index
    @invoices = Invoice.paginate(page:     params[:page],
                                 per_page: params[:per_page] || 20).order('created_at DESC')
  end
end
