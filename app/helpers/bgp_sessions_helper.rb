module BgpSessionsHelper
  def bgp_sessions_colspan(admin)
    admin ? 6 : 5
  end

  def bgp_sessions_table_onClick(bgp_session)
    if @enable_admin_view
      html = "onClick=\"location.href='".html_safe
      html << (@enable_admin_view ? edit_admin_bgp_session_path(bgp_session.id) : account_service_bgp_sessions_path(@account, @service, bgp_session.id))
      html << "'\"".html_safe
    end
  end
end
