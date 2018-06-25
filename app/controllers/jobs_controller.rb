class JobsController < ProtectedController
  def index
    @jobs = @account.jobs.paginate(:page => params[:page],
                                   :per_page => (params[:per_page] ||= 15).to_i).\
                                   order('created_at desc')
  end
end
