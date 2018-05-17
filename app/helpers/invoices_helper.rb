module InvoicesHelper
  def invoices_colspan(admin, action_name)
    if admin && action_name == 'index'
      9
    else
      8
    end
  end

  def invoice_paid_text(invoice)
    if invoice.paid?
      css_class = "paid"
      text = "Paid"
    else
      css_class = "unpaid"
      text = "Unpaid"
    end

    "<span class='#{css_class}'>#{text}</span>"
  end
end
