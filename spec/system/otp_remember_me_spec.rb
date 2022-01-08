require 'rails_helper'

RSpec.describe 'OTP remember me' do

  before do
    @chris = accounts(:chris)
    setup_2fa(@chris)

    @garry = accounts(:garry)
    setup_2fa(@garry)
  end

  it "can success remember me and skip OTP auth next 30 days", js: true do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

    token = get_an_onetime_token_from_authenticator_app(@chris)
    fill_in_digit_fields_with token
    check "Don't ask again for 30 days (on this device)"
    click_button "Verify"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    #############################
    ## Login again without 2FA ##
    #############################

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    ##################################
    ## Login with 2FA 30 days later ##
    ##################################
    travel_to 31.days.from_now do
      fill_in 'account[login]', with: 'chris'
      fill_in 'account[password]', with: '12345678'
      click_button "Login"
      expect(page).to have_content("Authenticate your account")
      expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

      token = get_an_onetime_token_from_authenticator_app(@chris)
      fill_in_digit_fields_with token
      click_button "Verify"
      expect(page).to have_content("Welcome chris, it is nice to see you.")
      expect(page.current_path).to eq(dashboard_path)
    end
  end

  it 'need to reauth OTP if does not select the OTP remember me checkbox', js: true do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

    token = get_an_onetime_token_from_authenticator_app(@chris)
    fill_in_digit_fields_with token
    uncheck "Don't ask again for 30 days (on this device)"
    click_button "Verify"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    ###########################
    ## Reauth with OTP again ##
    ###########################
    travel_to 30.seconds.after do
      fill_in 'account[login]', with: 'chris'
      fill_in 'account[password]', with: '12345678'
      click_button "Login"
      expect(page).to have_content("Authenticate your account")
      expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

      token = get_an_onetime_token_from_authenticator_app(@chris)
      fill_in_digit_fields_with token
      click_button "Verify"
      expect(page).to have_content("Welcome chris, it is nice to see you.")
      expect(page.current_path).to eq(dashboard_path)
    end
  end

  it "a login of another user will force others to do OTP auth again", js: true do
    visit root_path
    expect(page).to have_selector("caption", text: "Login")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

    token = get_an_onetime_token_from_authenticator_app(@chris)
    fill_in_digit_fields_with token
    check "Don't ask again for 30 days (on this device)"
    click_button "Verify"
    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    ###############################
    ## Garry(another user) login ##
    ###############################
    fill_in 'account[login]', with: 'garry'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Authenticate your account")
    expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

    token = get_an_onetime_token_from_authenticator_app(@garry)
    fill_in_digit_fields_with token
    check "Don't ask again for 30 days (on this device)"
    click_button "Verify"
    expect(page).to have_content("Welcome Garry, it is nice to see you.")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    ########################################
    ## Chris has to reauth with OTP again ##
    ########################################
    travel_to 30.seconds.after do
      fill_in 'account[login]', with: 'chris'
      fill_in 'account[password]', with: '12345678'
      click_button "Login"
      expect(page).to have_content("Authenticate your account")
      expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

      token = get_an_onetime_token_from_authenticator_app(@chris)
      fill_in_digit_fields_with token
      click_button "Verify"
      expect(page).to have_content("Welcome chris, it is nice to see you.")
      expect(page.current_path).to eq(dashboard_path)
    end
  end

end
