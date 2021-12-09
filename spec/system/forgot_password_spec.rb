require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe 'Forgot Password' do

  fixtures :all

  before do
    allow_any_instance_of(AccountsController).to receive(:newpass).with(8).and_return('jMVDr5yQ')
  end

  it 'user can success forgot and reset password' do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")
    expect(page).to have_content("Customer Control Panel")

    click_link "Forgot your password?"
    expect(page).to have_content("Recover Password")

    expect {
      fill_in "email", with: "chris@pledie.com"
      click_button "Submit"
      expect(page).to have_content("Thank you, your account details have been sent to chris@pledie.com.")
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("ARP Networks Account Information")
    expect(mail.body.to_s).to eq(<<~BODY
    Dear chris@pledie.com,

    A new password has been assigned to you using the Forgot Password form.  Your
    account details are as follows:

    Username: chris
    Password: jMVDr5yQ

    Click the link below to login:
    https://portal.arpnetworks.com/accounts/login

    ---
    ARP Networks, Inc.
    http://www.arpnetworks.com

    BODY
    )

    click_link "Login"
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: 'jMVDr5yQ'
    click_button "Login"

    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page).to have_content("chris's dashboard")
    expect(page).to have_content("Main Menu")
    expect(page.current_path).to eq(dashboard_path)
  end

end
