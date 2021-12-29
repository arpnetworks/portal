require 'rails_helper'

RSpec.describe "Disable 2FA on the 'Security' Page" do

  let(:chris) { accounts(:chris) }

  before do
    setup_2fa(chris)
    sign_in(chris)
  end

  it "can success disable 2FA and login without 2FA", js: true do
    visit root_path
    expect(page).to have_content("chris's dashboard")

    click_link "Security"
    expect(page).to have_content("Two-factor authentication")

    click_on "Disable"
    expect(page).to have_selector("a", text: "Set up two-factor authentication")
    expect(page).not_to have_content("Two-factor methods")
    expect(page).not_to have_content("Recovery Options")

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Security"
    expect(page).to have_content("Two-factor authentication")

    click_link "Set up two-factor authentication"
    expect(page).to have_content("Two-factor authentication setup")
    expect(page).to have_content("You will need a Google Authenticator(or another 2FA authentication app) to complete this process.")
    expect(page).to have_content("Scan the QR code into your app.")

    token = scan_the_qr_code_and_get_an_onetime_token(chris)
    fill_in_digit_fields_with token
    click_button "Confirm and activate"
    expect(page).to have_content("2FA Setup Success")
    expect(page).to have_selector("li", count: 12)

    click_on "Done"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))
    expect(page).to have_content("Authenticator app")
    expect(page).to have_content("Recovery codes")


    ####################
    ## Login with 2FA ##
    ####################

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    travel_to 30.seconds.after do
      fill_in 'account[login]', with: 'chris'
      fill_in 'account[password]', with: '12345678'
      click_button "Login"
      expect(page).to have_content("Enter 6-digit code from your two factor authenticator app.")

      token = get_an_onetime_token_from_authenticator_app(chris)
      fill_in_digit_fields_with token
      click_button "Verify"
      expect(page).to have_content("Welcome chris, it is nice to see you.")
      expect(page.current_path).to eq(dashboard_path)
    end
  end

end
