require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe 'Forgot Password' do

  fixtures :all

  it 'user can success forgot and reset password' do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")
    expect(page).to have_content("Customer Control Panel")

    click_link "Forgot your password?"
    expect(page).to have_content("Recover Password")

    expect {
      fill_in "account[email]", with: "chris@pledie.com"
      click_button "Submit"
      expect(page).to have_content("You will receive an email with instructions on how to reset your password in a few minutes.")
    }.to change { ActionMailer::Base.deliveries.count }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("Reset password instructions")
    expect(mail.body.to_s).to include("Dear chris@pledie.com,")
    expect(mail.body.to_s).to include("Someone has requested a link to change your password. You can do this through the link below.")

    matches = mail.body.to_s.scan(/http:\/\/runner:4000(\/accounts\/password\/edit\?reset_password_token=[A-Za-z0-9\-_=]+)\"/)
    chris_reset_password_path = matches.flatten.first
    visit chris_reset_password_path
    expect(page).to have_content("Change your password")

    fill_in 'account[password]', with: 'newpassword'
    fill_in 'account[password_confirmation]', with: 'newpassword'
    click_button "Change my password"
    expect(page).to have_content("Your password has been changed successfully. You are now signed in.")
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: 'newpassword'
    click_button "Login"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)
  end

end
