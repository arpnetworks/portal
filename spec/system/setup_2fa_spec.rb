require 'rails_helper'

RSpec.describe "Setup 2FA on the 'Security' Page" do

  let(:chris) { accounts(:chris) }

  before { sign_in(chris) }

  it "can success setup 2FA" do
    visit root_path
    expect(page).to have_content("chris's dashboard")

    click_link "Security"
    expect(page).to have_content("Two-factor authentication")

    click_link "Set up two-factor authentication"
    expect(page).to have_content("Two-factor authentication setup")
    expect(page).to have_content("You will need a Google Authenticator(or another 2FA authentication app) to complete this process.")
    expect(page).to have_content("Scan the QR code into your app.")

    click_on "Cancel"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))

    click_link "Set up two-factor authentication"
    expect(page).to have_content("Two-factor authentication setup")

    token = scan_the_qr_code_and_get_a_onetime_token(chris)
    fill_in "otp_code", with: token
    click_button "Confirm and activate"
    expect(page).to have_content("2FA Setup Success")
    expect(page).to have_content("Save this emergency backup code and store it somewhere safe. If you lose your phone, you can use backup codes to sign in.")
    expect(page).to have_selector("li", count: 10)
    all("li").each do |li|
      expect(li.text).to match(/\w{8}/)
    end

    click_on "Done"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))
    expect(page).to have_content("Authenticator app")
    expect(page).to have_content("Enabled")
    expect(page).to have_content("Recovery codes")

    click_button "Regenerate" # Regenerate recovery codes
    expect(page).to have_content("Regenerate Recovery Codes Success")
    expect(page).to have_content("Save this emergency backup code and store it somewhere safe. If you lose your phone, you can use backup codes to sign in. (The previous codes are all expired.)")
    expect(page).to have_selector("li", count: 10)
    all("li").each do |li|
      expect(li.text).to match(/\w{8}/)
    end

    click_on "Done"
    expect(page).to have_content("Two-factor authentication")
    expect(page.current_path).to eq(account_security_path(chris))
  end

  def scan_the_qr_code_and_get_a_onetime_token(user)
    user.reload.current_otp
  end

end
