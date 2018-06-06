module IpBlocksHelper
  def ip_blocks_colspan(admin)
    admin ? 7 : 7
  end

  def ip_blocks_table_onClick(ip)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? edit_admin_ip_block_path(ip.id) : account_service_ip_block_path(@account, @service, ip.id))
      html << "'\"".html_safe
    end
  end

  def subnet_wizard(ip_block)
    cidr_obj = ip_block.cidr_obj

    case cidr_obj.version
    when 4
      if cidr_obj.bits <= 29
        link_to(image_tag('/images/icons/wand.png', :alt => "Subnet Wizard"), subnet_admin_ip_block_path(ip_block))
      end
    when 6
      if cidr_obj.bits <= 48
        link_to(image_tag('/images/icons/wand.png', :alt => "Subnet Wizard"), subnet_admin_ip_block_path(ip_block))
      end
    end
  end
end
