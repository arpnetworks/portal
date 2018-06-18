module VirtualMachinesHelper
  def virtual_machines_colspan(admin)
    admin ? 6 : 5
  end

  def virtual_machines_table_onClick(vm)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? admin_virtual_machine_path(vm.id) : account_service_virtual_machine_path(@account, @service, vm.id))
      html << "'\"".html_safe
    end
  end
end
