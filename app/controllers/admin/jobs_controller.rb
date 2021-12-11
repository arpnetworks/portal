class Admin::JobsController < Admin::HeadQuartersController
  before_action :is_arp_admin?
  before_action :find_job, only: %i[show edit update destroy retry]

  def index
    @jobs = Job.paginate(page: params[:page],
                         per_page: params[:per_page] || 20).order('created_at DESC')
  end

  def destroy
    begin
      @job.destroy
    rescue ActiveRecord::StatementInvalid => e
      flash[:error] = 'There was an error deleting this record'
      flash[:error] += '<br/>'
      flash[:error] += e.message
    else
      flash[:notice] = "Job #{@job.id} (jid=#{@job.jid}) was deleted."
    end

    respond_to do |format|
      format.html { redirect_to admin_jobs_path }
      format.xml  { head :ok }
    end
  end

  def retry
    @new_job = @job.retry!

    flash[:notice] = "Sent retry message to Job #{@job.id} and Job #{@new_job.id} was created"

    respond_to do |format|
      format.html { redirect_to admin_jobs_path }
      format.xml  { head :ok }
    end
  end

  protected

  def find_job
    @job = Job.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Could not find Job with ID #{params[:id]}"
    redirect_to(admin_jobs_path)
  end
end
