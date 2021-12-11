require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe 'Update account' do

  fixtures :all

  before { sign_in(accounts(:chris)) }

  it 'Account can success update its info' do
    visit root_path
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)

    click_link "Edit Profile"
    expect(page).to have_content("Edit your account profile")

    fill_in "account[email2]", with: "chris2@test.com"
    fill_in "account[email_billing]", with: "billing@chris.com"
    fill_in "account[company]", with: "ARP-Test"
    fill_in "account[first_name]", with: "Chris"
    fill_in "account[last_name]", with: "Brook"
    fill_in "account[address1]", with: "127 Mattson Street"
    fill_in "account[address2]", with: "Apartment 123"
    fill_in "account[city]", with: "Portland"
    fill_in "account[state]", with: "OR"
    fill_in "account[zip]", with: "97205"
    fill_in "account[country]", with: "US"
    click_button "Save changes"
    expect(page).to have_content("Changes saved")
    expect(page).to have_field("account[email2]", with: "chris2@test.com")
    expect(page).to have_field("account[email_billing]", with: "billing@chris.com")
    expect(page).to have_field("account[company]", with: "ARP-Test")
    expect(page).to have_field("account[first_name]", with: "Chris")
    expect(page).to have_field("account[last_name]", with: "Brook")
    expect(page).to have_field("account[address1]", with: "127 Mattson Street")
    expect(page).to have_field("account[address2]", with: "Apartment 123")
    expect(page).to have_field("account[city]", with: "Portland")
    expect(page).to have_field("account[state]", with: "OR")
    expect(page).to have_field("account[zip]", with: "97205")
    expect(page).to have_field("account[country]", with: "US")

    fill_in "account[password]", with: "abc123456"
    fill_in "account[password_confirmation]", with: "abc123456"
    click_button "Save changes"
    expect(page).to have_content("You need to sign in or sign up before continuing.")
    expect(page.current_path).to eq(new_account_session_path)

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: 'abc123456'
    click_button "Login"
    expect(page).to have_content("Welcome ARP-Test, it is nice to see you.")
    expect(page.current_path).to eq(edit_account_path(accounts(:chris)))
  end

end
