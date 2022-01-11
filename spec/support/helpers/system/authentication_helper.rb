module AuthenticationSystemHelper
  def login(account, password: "12345678")
    visit new_account_session_path
    expect(page).to have_content("Customer Control Panel")


    if current_account.otp_required_for_login
      fill_in 'account[login]', with: account.login
      fill_in 'account[password]', with: password
      click_button "Login"
      expect(page).to have_content("Enter the 6-digit code from your two factor authenticator app.")

      token = get_an_onetime_token_from_authenticator_app(chris)
      fill_in_digit_fields_with token
      click_button "Verify"
      expect(page).to have_content("Welcome #{account.login}, it is nice to see you.")
    else
      fill_in 'account[login]', with: account.login
      fill_in 'account[password]', with: password
      click_button "Login"
      expect(page).to have_content("Welcome #{account.login}, it is nice to see you.")
    end
  end

  def scan_the_qr_code_and_get_an_onetime_token(account)
    account.reload.current_otp
  end

  def get_an_onetime_token_from_authenticator_app(account)
    account.reload.current_otp
  end

  def fill_in_digit_fields_with(number)
    chars = number.to_s.split('')

    chars.each.with_index do |char, index|
      fill_in "digit-#{index + 1}", with: char
    end
  end

  def setup_2fa(account)
    account.otp_secret = Account.generate_otp_secret
    account.otp_required_for_login = true
    account.generate_otp_backup_codes!
    account.save!
  end
end
