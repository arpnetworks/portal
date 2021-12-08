require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe 'Sign up', type: :system do

  it 'test', debug: true, js: true do
    visit root_path

    expect(page).to have_selector("caption", text: "Login")
    expect(page).to have_content("Customer Control Panel")
  end

end
