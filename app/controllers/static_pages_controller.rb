class StaticPagesController < ProtectedController
  layout 'responsive'

  def help
    expiry = Account.tender_token_expiry_timestamp
    url_encoded_email = CGI.escape(@account.email)
    @tender_link = "http://support.arpnetworks.com/login?email=#{url_encoded_email}&expires=#{expiry}&hash=#{@account.tender_token(expiry)}"

    @zammad_link = current_account.zammad_sso_url
  end
end
