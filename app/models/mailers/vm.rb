class MailerVm < ApplicationMailer
  helper ActionView::Helpers::UrlHelper

  def setup_complete(vps)
    @vps = vps
    @account = vps.account

    @subject    = "Server Setup Complete"
    @from       = "ARP Networks <support@arpnetworks.com>"
    @recipients = @account.email
    @bcc        = 'gdolley@arpnetworks.com'

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end
end
