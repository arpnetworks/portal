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

  def sales_receipt(account, opts = {})
    begin
      @config = YAML.load(File.read(Rails.root + "config/arp/globals.yml"))
      subject_addition = "; " + @config[Rails.env]['sr_subject']
    rescue
      subject_addition = ""
    end

    @account = account
    @hosted_invoice_url = opts[:hosted_invoice_url]

    @subject    = "Sales Receipt (#{Time.new.strftime("%b. %Y")})" + subject_addition
    @from       = "ARP Networks <billing@arpnetworks.com>"
    @recipients = @account.email_for_sales_receipts

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end
end
