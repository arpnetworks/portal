module Admin::AccountsHelper
  def accounts_table_onClick(account)
     html = "onClick=\"location.href='".html_safe
     html << admin_account_path(account)
     html << "'\"".html_safe
  end
end
