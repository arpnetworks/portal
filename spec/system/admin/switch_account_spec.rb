require 'rails_helper'

RSpec.describe "Admin - Switch Account" do

  before do
    super_admin = create(:account, login: 'john', email: 'john@example.com')
    sign_in(super_admin)
  end

  it "An super admin can switch account" do
    visit admin_path
    expect(page).to have_content("Administration Dashboard")

    select "chris", from: "user[login]"
    click_button "Switch User"
    expect(page).to have_content("chris's dashboard")
    expect(page.current_path).to eq(dashboard_path)
  end

end
