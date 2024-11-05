class MailerPreview < ActionMailer::Preview
  def new_order_from_stripe
    product = { plan: 'allpurpose', code: 'vps', description: 'VPS', os_code: 'freebsd-12.1-amd64', location: 'lax',
                ip_block: '/29' }

    customer = { first_name: 'John', last_name: 'Doe', fullname: 'John Doe', email: 'john.doe@example.com',
                 company: 'Test Company', address1: '123 Main St', address2: '', city: 'Anytown', state: 'CA',
                 postal_code: '12345', country: 'USA', existing_account: true }

    additional = { additional_instructions: 'My special instructions' }

    # Or no additional instructions
    # additional = {}

    # Or multiline
    additional = { additional_instructions: "Line 1\nLine 2\nLine 3" }
    
    Mailer.new_order_from_stripe('si_Qifoz0', product, customer, additional)
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
