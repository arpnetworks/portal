module BillingSystemModels
  class Mailer < ActionMailer::Base
    cattr_accessor :decline_notice_headers
    cattr_accessor :sales_receipt_headers

    @@decline_notice_headers = {
      :subject => "Your credit card has declined",
      :from    => "noreply@example.com"
    }

    @@sales_receipt_headers = {
      :subject => "Sales receipt",
      :from    => "noreply@example.com"
    }

    def decline_notice(account)
      if account.email_for_sales_receipts
        @subject = self.class.decline_notice_headers[:subject]
        @from    = self.class.decline_notice_headers[:from]
        @cc      = self.class.decline_notice_headers[:cc]

        @recipients = [account.email_for_sales_receipts]

        @account = account

        mail(to: @recipients, subject: @subject, from: @from, cc: @cc)
      end
    end

    def sales_receipt(sales_receipt, charge = nil)
      account = sales_receipt.account

      if account.email_for_sales_receipts
        @subject = self.class.sales_receipt_headers[:subject]
        @from    = self.class.sales_receipt_headers[:from]
        @cc      = self.class.sales_receipt_headers[:cc]

        @recipients = [account.email_for_sales_receipts]

        @sr = sales_receipt
        @charge = charge

        mail(to: @recipients, subject: @subject, from: @from, cc: @cc)
      end
    end
  end
end
