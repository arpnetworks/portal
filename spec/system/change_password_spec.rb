require 'rails_helper'

RSpec.describe "Change password on the 'Security' Page" do

  let(:chris) { accounts(:chris) }

  before { sign_in(chris) }

  it "can success change password" do
    visit root_path
    expect(page).to have_content("chris's dashboard")

    click_link "Security"
    expect(page).to have_content("Two-factor authentication")

    click_button "Update password"
    expect(page).to have_content("Current password can't be blank")

    fill_in "account[current_password]", with: "12345678"
    fill_in "account[password]", with: "abc123456"
    click_button "Update password"
    expect(page).to have_content("Password confirmation doesn't match Password")

    fill_in "account[current_password]", with: "12345678"
    fill_in "account[password]", with: "abc123456"
    fill_in "account[password_confirmation]", with: "abc123456"
    click_button "Update password"
    expect(page).to have_content("Your password has been changed successfully. You are now signed in.")

    click_link "Logout"
    expect(page).to have_content("You have been logged out.")

    fill_in'account[login]', with: 'chris'
    fill_in 'account[password]', with: 'abc123456'
    click_button "Login"
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)
  end

end
