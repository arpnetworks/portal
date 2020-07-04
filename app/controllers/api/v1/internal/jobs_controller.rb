class Api::V1::Internal::JobsController < ApiController
  before_action :trusted_hosts
  before_action :find_job, only: [:event, :retval]

  skip_before_action :verify_authenticity_token, only: [:event]

  def event
    event = params[:event]
    args  = params[:args]

    unless event
      render :plain => "No event specified\n", :status => 412 and return
    end

    begin
      @job.send "#{event}!"
    rescue AASM::InvalidTransition
      valid_transitions = @job.aasm.events

      text = "Invalid transition.\n"

      if !valid_transitions.empty?
        text += "\n"
        text += "Valid transitions: #{valid_transitions.join(', ')}\n"
      end

      render :plain => text, :status => 500 and return
    end

    case event
    when 'finish'
      if args
        @job.retval = args
        @job.save!
      end
    when 'cancel', 'fail'
      if args
        @job.reason = args
        @job.save!
      end
    end

    render :plain => "Job #{@job.id} state is now #{@job.aasm_state}\n"
  end

  private

  def find_job
    id = params[:id]

    begin
      @job = Job.find id
    rescue ActiveRecord::RecordNotFound
      render :plain => "Job #{id} not found\n", :status => 404
    end
  end

  def trusted_hosts
    trusted_vm_hosts
  end
end
