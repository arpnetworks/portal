class MailerPreview < ActionMailer::Preview
  def new_order_from_stripe
    product = { code: 'vps', description: 'VPS', os: 'FreeBSD 12.1', os_code: 'freebsd-12.1-amd64', location: 'lax',
                ip_block: '/29' }
    Mailer.new_order_from_stripe('si_Qifoz0', product, { first_name: 'John', last_name: 'Doe', fullname: 'John Doe', email: 'john.doe@example.com' })
  end

  def welcome_new_customer
    account = Account.new(
      email: 'test@example.com',
      first_name: 'John',
      last_name: 'Doe',
      company: 'Test Company'
    )
    
    login = 'testuser'
    password = 'password123'

    Mailer.welcome_new_customer(account, login, password)
  end
end
