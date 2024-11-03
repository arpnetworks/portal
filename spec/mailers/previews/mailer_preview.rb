class MailerPreview < ActionMailer::Preview
  def new_order_from_stripe
    product = { code: 'vps', description: 'VPS', os: 'Linux', location: 'lax' }
    Mailer.new_order_from_stripe('si_Qifoz0', product)
  end
end
