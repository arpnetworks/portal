require 'rails_helper'
require 'arp_spec_helper'

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

end
