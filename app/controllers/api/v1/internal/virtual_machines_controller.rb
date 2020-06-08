class Api::V1::Internal::VirtualMachinesController < ApiController
  before_action :trusted_hosts, except: [:phone_home]
  before_action :find_virtual_machine, only: %i[status phone_home]

  skip_before_action :verify_authenticity_token

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

    uuids = {}
    data.split(';').each do |vm_and_status|
      uuid, status = vm_and_status.split(',')
      uuids[uuid] = status
    end

    sql_partial = ''
    uuids.keys.each do |k|
      sql_partial += "'#{k}', "
    end
    sql_partial = sql_partial[0..-3]

    all_vms_raw = VirtualMachine.connection.select_all("SELECT uuid,status FROM virtual_machines WHERE uuid IN (" + sql_partial + ")")

    begin
      all_vms_raw.each do |vm_and_status_in_db|
        status_in_db = vm_and_status_in_db['status']
        new_status = uuids[vm_and_status_in_db['uuid']]
        if status_in_db != new_status
          vm = VirtualMachine.find_by(uuid: vm_and_status_in_db['uuid'])
          vm.update_column(:status, new_status)
        end
      end
    rescue Exception => e
      render(text: "We encountered an error: #{e.message}") && (return)
    end

    render text: 'Performed without errors'
  end

  def phone_home
    @virtual_machine.update(provisioning_status: 'done')

    render text: "Done\n"
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
