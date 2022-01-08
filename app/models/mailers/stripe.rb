class Mailers::Stripe < ApplicationMailer
  helper ActionView::Helpers::UrlHelper

  def payment_failed(account, opts = {})
    @account = account
    @hosted_invoice_url = opts[:hosted_invoice_url]

    @subject    = "[Action Required] Payment Method Declined"
    @from       = "ARP Networks <billing@arpnetworks.com>"
    @recipients = @account.email_for_sales_receipts
    @bcc        = 'gdolley@arpnetworks.com'

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end

  def sales_receipt(invoice, opts = {})
    begin
      @config = YAML.load(File.read(Rails.root + "config/arp/globals.yml"))
      subject_addition = "; " + @config[Rails.env]['sr_subject']
    rescue
      subject_addition = ""
    end

    @invoice = invoice
    @account = invoice.account
    @payment = invoice.payments.first # We assume the first one holds the info we need
    @hosted_invoice_url = opts[:hosted_invoice_url]

    @subject    = "Sales Receipt (#{Time.new.strftime("%b. %Y")})" + subject_addition
    @from       = "ARP Networks <billing@arpnetworks.com>"
    @recipients = @account.email_for_sales_receipts

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end

  def refund(account, amount, opts = {})
    @account = account
    @receipt_url = opts[:receipt_url]
    @refund_amount = sprintf('$%01.2f USD', amount)

    @subject    = "Refund Receipt"
    @from       = "ARP Networks <billing@arpnetworks.com>"
    @recipients = @account.email_for_sales_receipts
    @bcc        = 'billing@arpnetworks.com'

    mail(to: @recipients, from: @from, subject: @subject, bcc: @bcc)
  end
end
