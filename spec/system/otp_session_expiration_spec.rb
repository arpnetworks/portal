require 'rails_helper'

RSpec.describe 'OTP session expiration (expire after 30 seconds)' do

  before do
    chris = accounts(:chris)
    setup_2fa(chris)
  end

  it "refresh on '/account/sign_in/otp'", js: true do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter 6-digit code from your two factor authenticator app.")

    refresh
    expect(page).to have_content("Enter 6-digit code from your two factor authenticator app.")
    expect(page.current_path).to eq("/accounts/sign_in/otp")

    travel_to 31.seconds.after do
      refresh
      expect(page).to have_selector("caption", text: "Login")
      expect(page.current_path).to eq("/accounts/sign_in")
    end
  end

  it "refresh on '/account/sign_in/recovery_code'", js: true do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Enter 6-digit code from your two factor authenticator app.")

    click_link "Use a recovery code to access your account"
    expect(page).to have_content("Authenticate your account with a recovery code")
    expect(page).to have_content("To access your account, enter one of the recovery codes you saved when you set up your two-factor authentication device.")

    refresh
    expect(page).to have_content("To access your account, enter one of the recovery codes you saved when you set up your two-factor authentication device.")
    expect(page.current_path).to eq("/accounts/sign_in/recovery_code")

    travel_to 31.seconds.after do
      refresh
      expect(page).to have_selector("caption", text: "Login")
      expect(page.current_path).to eq("/accounts/sign_in")
    end
  end

end
