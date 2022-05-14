class Api::V1::Internal::VirtualMachinesController < ApiController
  before_action :trusted_hosts, except: [:phone_home]
  before_action :find_virtual_machine, only: %i[status phone_home]

  skip_before_action :verify_authenticity_token

  def status
    @old_status = @virtual_machine.status
    @new_status = params[:status]

    @virtual_machine.status = @new_status
    @virtual_machine.save

    render plain: "Updated status for VM #{@virtual_machine.uuid} from #{@old_status} to #{@new_status}\n"
  end

  # Like status, but in batch
  def statuses
    data = request.raw_post.to_s

    hosts = {}
    uuids = {}
    data.split(';').each do |vm_and_status|
      uuid, status, host = vm_and_status.split(',')
      uuids[uuid] = status
      hosts[uuid] = host
    end

    sql_partial = ''
    uuids.each_key do |k|
      sql_partial += "'#{k}', "
    end
    sql_partial = sql_partial[0..-3]

    all_vms_raw = VirtualMachine.connection.select_all('SELECT uuid,status FROM virtual_machines WHERE uuid IN (' + sql_partial + ')')

    begin
      all_vms_raw.each do |vm_and_status_in_db|
        status_in_db = vm_and_status_in_db['status']
        new_status = uuids[vm_and_status_in_db['uuid']]
        new_host = hosts[vm_and_status_in_db['uuid']]
        if status_in_db != new_status
          vm = VirtualMachine.find_by(uuid: vm_and_status_in_db['uuid'])
          vm.update_column(:status, new_status)
          vm.update_column(:host, Host.normalize_host(new_host)) if new_host
        end
      end
    rescue Exception => e
      render(plain: "We encountered an error: #{e.message}") && (return)
    end

    render plain: 'Performed without errors'
  end

  def phone_home
    @virtual_machine.update(provisioning_status: 'done')

    if @virtual_machine.ssh_host_keys.empty?
      [params[:pub_key_rsa],
       params[:pub_key_dsa],
       params[:pub_key_ecdsa],
       params[:pub_key_ed25519]].each do |key|
         @virtual_machine.set_ssh_host_key(key) if key
       end

       begin
         Mailers::Vm.setup_complete(@virtual_machine).deliver_now
       rescue StandardError => e
         logger.error 'There was an error sending the VM setup complete email: ' + e.message
       end
    end

    render plain: "Done\n"
  end

  private

  def find_virtual_machine
    uuid = params[:uuid]

    begin
      @virtual_machine = VirtualMachine.find_by(uuid: uuid)

      raise ActiveRecord::RecordNotFound unless @virtual_machine
    rescue ActiveRecord::RecordNotFound
      render plain: "Virtual Machine with UUID #{uuid} not found\n", status: :not_found
      nil
    end
  end

  def trusted_hosts
    trusted_vm_hosts
  end
end
