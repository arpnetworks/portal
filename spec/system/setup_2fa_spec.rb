require 'rails_helper'

RSpec.describe "Setup 2FA on the 'Security' Page" do

  let(:chris) { accounts(:chris) }

  before { sign_in(chris) }

  it "can success setup 2FA and login with it", js: true do
    visit root_path
    expect(page).to have_content("chris's dashboard")

    click_link "Security"
    expect(page).to have_content("Two-factor authentication")

    click_link "Set up two-factor authentication"
    expect(page).to have_content("Two-factor authentication setup")
    expect(page).to have_content("You will need an authenticator app")
    expect(page).to have_content("to complete this process")
    expect(page).to have_content("Scan the QR code into your app.")

    click_on "Cancel"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))

    click_link "Set up two-factor authentication"
    expect(page).to have_content("Two-factor authentication setup")

    token = scan_the_qr_code_and_get_an_onetime_token(chris)
    fill_in_digit_fields_with token
    click_button "Confirm and activate"
    expect(page).to have_content("2FA Setup Success")
    expect(page).to have_content("Save these emergency backup codes and store them somewhere safe. If you lose your phone, you can use backup codes to sign in.")
    expect(page).to have_selector("li", count: 12)
    all("li").each do |li|
      expect(li.text).to match(/\w{8}/)
    end

    click_on "Done"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))
    expect(page).to have_content("Authenticator app")
    expect(page).to have_selector("a[data-method='delete']", text: "Disable")
    expect(page).to have_content("Recovery codes")

    click_on "Regenerate" # Regenerate recovery codes
    expect(page).to have_content("Regenerate Recovery Codes Success")
    expect(page).to have_content("Save these emergency backup codes and store them somewhere safe. If you lose your phone, you can use backup codes to sign in. All previous codes are now expired.")
    expect(page).to have_selector("li", count: 12)
    save_recovery_codes

    click_on "Done"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))


    ####################
    ## Login with 2FA ##
    ####################

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    travel_to 30.seconds.after do
      fill_in 'account[login]', with: 'chris'
      fill_in 'account[password]', with: '12345678'
      click_button "Login"
      expect(page).to have_content("Authenticate your account")
      expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

      fill_in_digit_fields_with '111111'
      click_button "Verify"
      expect(page).to have_content("Failed to authenticate your code")

      token = get_an_onetime_token_from_authenticator_app(chris)
      fill_in_digit_fields_with token
      uncheck "Don't ask again for 30 days (on this device)"
      click_button "Verify"
      expect(page).to have_content("Welcome chris, it is nice to see you.")
      expect(page.current_path).to eq(dashboard_path)
    end

    ##############################
    ## Login with a backup code ##
    ##############################
    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

    click_link "Use a recovery code to access your account"
    expect(page).to have_content("Authenticate your account with a recovery code")
    expect(page).to have_content("To access your account, enter one of the recovery codes you saved when you set up your two-factor authentication device.")

    fill_in_digit_fields_with '1234abcd'
    click_button "Verify"
    expect(page).to have_content("Failed to authenticate your code")

    fill_in_digit_fields_with @recovery_codes.pop
    click_button "Verify"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)
  end

  def save_recovery_codes
    @recovery_codes = all("li").map(&:text)
  end

end
