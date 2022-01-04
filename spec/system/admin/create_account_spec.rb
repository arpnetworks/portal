require 'rails_helper'

RSpec.describe 'Admin - Create an account' do

  before { sign_in(accounts(:admin)) }

  it 'admin can success create an account' do
    visit root_path
    expect(page).to have_content("admin's dashboard")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Admin"
    expect(page).to have_content("Administration Dashboard")

    click_link "All Accounts"
    expect(page).to have_selector(".title", text: "All Accounts")

    click_link "New Account"
    expect(page).to have_selector("caption", text: "New Account")

    fill_in "account[login]", with: "john"
    fill_in "account[email]", with: "john@example.com"
    fill_in "account[password]", with: "12345678"
    fill_in "account[password_confirmation]", with: "12345678"
    fill_in "account[stripe_customer_id]", with: "abc123"
    click_button "Create"

    expect(page).to have_selector("td", text: "john")
    expect(page).to have_selector("td", text: "john@example.com")

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in 'account[login]', with: 'john'
    fill_in 'account[password]', with: '12345678'
    click_button "Login"
    expect(page).to have_content("Welcome john, it is nice to see you.")
  end

end
