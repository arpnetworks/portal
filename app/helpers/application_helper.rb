# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Format

  def render_flash(custom_flash = nil)
    message = custom_flash || flash
    flash_types = [:error, :warning, :notice]
    flash_type = flash_types.detect { |a| message.keys.include?(a) }
    "<div id='flash_%s_div' class='flash_%s rounded'>%s</div>" % [flash_type.to_s, flash_type.to_s, message[flash_type]] if flash_type
  end

  def billing_interval_in_words(number_of_months)
    return "Never" if number_of_months.nil?

    case number_of_months.to_i
    when 0
      "Never"
    when 1
      "Monthly"
    when 3
      "Quarterly"
    when 12
      "Annual"
    else
      "Every #{number_of_months} months"
    end
  end

  def service_total_in_words(total, number_of_months)
    return "No charges" if total == 0

    case number_of_months.to_i
    when 0
      "Non-recurring Charges: $#{total}"
    when 1
      "#{billing_interval_in_words(number_of_months)} Recurring Charges: $#{total}"
    when 3
      "#{billing_interval_in_words(number_of_months)} Recurring Charges: $#{total}"
    when 12
      "#{billing_interval_in_words(number_of_months)} Recurring Charges: $#{total}"
    else
      "#{billing_interval_in_words(number_of_months)} Recurring Charges: $#{total}"
    end
  end

  def one_line_address_for_account(account)
    s = ""

    %w(city state zip country).each do |attr|
      if (attr_text = account.send(attr)) && (attr_text != '')
        s += attr_text + ", "
      end
    end

    if s == ''
      s = account.address1
      if s == ''
        s = account.address2
      else
        s += ", " + account.address2 if account.address2
      end
    end

    s = '' if s.nil?

    s.chomp(", ")
  end

  def services_table_onClick(service)
    unless @enable_pending_view
      String.new("onClick=\"location.href='" + (@enable_admin_view ? admin_service_path(service.id) : account_service_path(@account, service.id)) + "'\"").html_safe
    else
      ""
    end
  end

  def vlans_table_onClick(vlan)
    if vlan.new_record?
      ""
    else
      String.new("onClick=\"location.href='" + edit_admin_vlan_path(vlan.id) + "'\"").html_safe
    end
  end

  def vlans_table_highlight(vlan)
    if vlan.new_record?
      "no_highlight"
    else
      ""
    end
  end

  def dns_records_table_onClick(account, record)
    if account.owns_dns_record?(record)
      String.new("onClick=\"location.href='" + edit_account_dns_record_path(account.id, record.id) + "'\"").html_safe
    else
      ""
    end
  end

  def invoices_table_onClick(invoice)
    unless @enable_pending_view
      String.new("onClick=\"location.href='" + (@enable_admin_view ? admin_invoice_path(invoice.id) : account_invoice_path(@account, invoice.id)) + "'\"").html_safe
    else
      ""
    end
  end

  def jobs_table_onClick(job)
    if @enable_admin_view
      String.new("onClick=\"location.href='" + admin_job_path(job.id) + "'\"").html_safe
    else
      ""
    end
  end

  def admin_account_path_from_resource(resource)
    if resource && resource.service
      link_to(h(resource.service.account.display_account_name), admin_account_path(resource.service.account))
    end
  end
end
