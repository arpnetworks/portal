require 'rails_helper'

RSpec.describe 'Disable Sign Up' do

  it 'redirect "/accounts/new" to "https://arpnetworks.com"' do
    get "/accounts/new"
    expect(response).to redirect_to("https://arpnetworks.com")
  end

  it 'redirect "/accounts/sign_up" to "https://arpnetworks.com"' do
    get "/accounts/sign_up"
    expect(response).to redirect_to("https://arpnetworks.com")
  end

end
