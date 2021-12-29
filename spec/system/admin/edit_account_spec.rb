require 'rails_helper'

RSpec.describe 'Admin - Edit an account' do

  before { sign_in(accounts(:admin)) }

  it 'admin can success edit an account' do
    visit root_path
    expect(page).to have_content("admin's dashboard")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Admin"
    expect(page).to have_content("Administration Dashboard")

    click_link "All Accounts"
    expect(page).to have_selector(".title", text: "All Accounts")

    chris_edit_button = find("a[href='/admin/accounts/#{accounts(:chris).id}/edit']")
    chris_edit_button.click
    expect(page).to have_selector("caption", text: "Edit Account")

    fill_in "account[login]", with: "chris-new"
    fill_in "account[email]", with: "chris-new@pledie.com"
    fill_in "account[password]", with: "abcd1234"
    fill_in "account[password_confirmation]", with: "abcd1234"
    click_button "Save changes"
    expect(page).to have_content("Changes saved")

    click_link "Back to All Accounts"
    expect(page).to have_selector("td", text: "chris-new")
    expect(page).to have_selector("td", text: "chris-new@pledie.com")

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in 'account[login]', with: 'chris-new'
    fill_in 'account[password]', with: 'abcd1234'
    click_button "Login"
    expect(page).to have_content("Welcome chris-new, it is nice to see you.")
  end

end
