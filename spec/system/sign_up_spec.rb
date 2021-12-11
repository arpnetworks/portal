require 'rails_helper'

RSpec.describe 'Sign Up' do

  fixtures :all

  it 'user can success sign up' do
    visit root_path
    expect(page).to have_content("Customer Control Panel")

    click_link "Register"
    expect(page).to have_content("A valid email is required to activate your account. Your email will never be shared with anyone.")

    click_button "Register"
    # expect(page).to have_content("8 errors prohibited this account from being saved")
    expect(page).to have_content("5 errors prohibited this account from being saved")
    expect(page).to have_content("Password can't be blank")
    # expect(page).to have_content("Password is too short (minimum is 8 characters)")
    expect(page).to have_content("Login can't be blank")
    expect(page).to have_content("Login is too short (minimum is 3 characters)")
    expect(page).to have_content("Login can contain only numbers and letters.")
    expect(page).to have_content("Email can't be blank")
    # expect(page).to have_content("Email is invalid")
    # expect(page).to have_content("Password confirmation can't be blank")

    fill_in 'account[login]', with: 'john'
    fill_in 'account[email]', with: 'john@example.com'
    fill_in 'account[password]', with: '12345678'
    fill_in 'account[password_confirmation]', with: '12345678'
    click_button "Register"
    expect(page).to have_content("Your account has been created!")
    expect(page).to have_content("john's dashboard")
    expect(page).to have_content("Main Menu")
    expect(page.current_path).to eq(dashboard_path)
  end

end
