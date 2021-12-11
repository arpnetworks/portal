require 'rails_helper'

RSpec.describe Accounts::SessionsController do

  fixtures :all

  it 'should remember the requested location in a non-logged-in state and redirect.' do
    set_session(account_return_to: 'http://www.google.com')
    post account_session_path, params: { account: { login: "admin", password: "12345678" } }
    expect(response).to redirect_to('http://www.google.com')
  end

  it 'should redirect to dashboard if already logged in' do
    sign_in accounts(:chris)
    get new_account_session_path
    expect(response).to redirect_to(dashboard_path)
  end

  it "The user who hasn't authenticated with Devise can successfully sign in and store password with Devise" do
    garry = accounts(:garry)
    expect(garry.encrypted_password).to be_blank
    expect(garry.valid_password?("12345678")).to eq(false)

    post account_session_path, params: { account: { login: 'garry', password: "12345678" } }

    expect(response).to redirect_to(dashboard_path)
    garry.reload
    expect(garry.encrypted_password).not_to be_blank
    expect(garry.valid_password?("12345678")).to eq(true)
  end

  it "login will generate and set a derived key in session[:dk]", focus: true do
    post account_session_path, params: { account: { login: 'chris', password: "12345678" } }
    expect(response).to redirect_to(dashboard_path)
    # Must match base64 encode
    expect(get_session(:dk)).to match(/^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/)
  end

end
