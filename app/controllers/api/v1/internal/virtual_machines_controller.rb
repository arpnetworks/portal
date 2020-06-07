class Api::V1::Internal::VirtualMachinesController < ApiController
  before_action :trusted_hosts
  before_action :find_virtual_machine, only: [:status]

  skip_before_action :verify_authenticity_token, only: %i[status statuses]

  def status
    @old_status = @virtual_machine.status
    @new_status = params[:status]

    @virtual_machine.status = @new_status
    @virtual_machine.save

    render text: "Updated status for VM #{@virtual_machine.uuid} from #{@old_status} to #{@new_status}\n"
  end

  # Like status, but in batch
  def statuses
    data = request.raw_post.to_s

    data.split(';').each do |vm_and_status|
      uuid, status = vm_and_status.split(',')

      begin
        vm = VirtualMachine.find_by(uuid: uuid, status: status)

        # If found, this VM's status has not changed, so we do not need to update
        # anything, otherwise...
        unless vm
          vm = VirtualMachine.find_by(uuid: uuid)

          # Does not run callbacks
          vm&.update_column(:status, status)
        end
      rescue Exception => e
        render(text: "We encountered an error: #{e.message}") && (return)
      end
    end

    render text: 'Performed without errors'
  end

  private

  def find_virtual_machine
    uuid = params[:uuid]

    begin
      @virtual_machine = VirtualMachine.find_by(uuid: uuid)

      raise ActiveRecord::RecordNotFound unless @virtual_machine
    rescue ActiveRecord::RecordNotFound
      render text: "Virtual Machine with UUID #{uuid} not found\n", status: :not_found
      nil
    end
  end

  def trusted_hosts
    trusted_vm_hosts
  end
end
