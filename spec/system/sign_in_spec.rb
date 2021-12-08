require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe 'Sign In' do

  fixtures :all

  it 'user can success sign in' do
    visit root_path

    expect(page).to have_selector("caption", text: "Login")
    expect(page).to have_content("Customer Control Panel")

    click_button "Login"
    expect(page).to have_content("Incorrect username and/or password, please try again.")

    fill_in 'account[login]', with: 'chris'
    fill_in 'account[password]', with: '123456'
    click_button "Login"

    expect(page).to have_content("Welcome chris, it is nice to see you.")
    expect(page).to have_content("chris's dashboard")
    expect(page).to have_content("Main Menu")
    expect(page.current_path).to eq(dashboard_path)
  end

end
