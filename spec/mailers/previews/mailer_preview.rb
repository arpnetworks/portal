class MailerPreview < ActionMailer::Preview
  def new_order_from_stripe
    product = { code: 'vps', description: 'VPS', os: 'FreeBSD 12.1', os_code: 'freebsd-12.1-amd64', location: 'lax',
                ip_block: '/29' }
    Mailer.new_order_from_stripe('si_Qifoz0', product, { name: 'John Doe', email: 'john.doe@example.com' })
  end
end
