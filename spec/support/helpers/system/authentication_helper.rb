module AuthenticationSystemHelper
  def login(account, password: "12345678")
    visit new_account_session_path
    expect(page).to have_content("Customer Control Panel")

    fill_in 'account[login]', with: account.login
    fill_in 'account[password]', with: password
    click_button "Login"
    expect(page).to have_content("Welcome #{account.login}, it is nice to see you.")
  end
end