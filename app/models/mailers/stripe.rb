class Mailers::Stripe < ApplicationMailer
  helper ActionView::Helpers::UrlHelper

  def payment_failed(account, opts = {})
    @account = account
    @hosted_invoice_url = opts[:hosted_invoice_url]

    @subject    = "Updated Credit Card Information Required"
    @from       = "ARP Networks <billing@arpnetworks.com>"
    @recipients = @account.email_for_sales_receipts
    @bcc        = 'gdolley@arpnetworks.com'

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end
end
