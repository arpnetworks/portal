module BgpSessionsPrefixesHelper
  def bgp_sessions_prefixes_colspan(admin)
    admin ? 5 : 4
  end

  def bgp_sessions_prefixes_table_onClick(bgp_sessions_prefix)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? edit_admin_bgp_sessions_prefix_path(bgp_sessions_prefix.id) : account_service_bgp_sessions_prefixes_path(@account, @service, bgp_sessions_prefix.id))
      html << "'\"".html_safe
    end
  end
end
