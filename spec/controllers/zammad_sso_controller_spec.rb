require 'rails_helper'

describe ZammadSsoController do
  describe '#verify' do
    let(:email) { 'user@example.com' }
    let(:first_name) { 'Test' }
    let(:last_name) { 'User' }
    let(:expires) { 5.minutes.from_now.to_i }
    let(:account) { create(:account, email: email, first_name: first_name, last_name: last_name) }
    let(:encoded_first_name) { Base64.strict_encode64(first_name) }
    let(:encoded_last_name) { Base64.strict_encode64(last_name) }
    let(:digest_string) do
      Zammad.digest_string(
        Zammad::ZAMMAD_HOST,
        email,
        expires,
        encoded_first_name,
        encoded_last_name
      )
    end
    let(:token) do
      OpenSSL::HMAC.hexdigest(
        'SHA256',
        Zammad::ZAMMAD_SECRET,
        digest_string
      )
    end
    let(:query) do
      "email=#{CGI.escape(email)}&expires=#{expires}&fn=#{encoded_first_name}&ln=#{encoded_last_name}&token=#{token}"
    end
    let(:uri) { "https://#{Zammad::ZAMMAD_HOST}/auth/sso?#{query}" }

    before do
      request.headers['X-Original-URI'] = uri
    end

    it 'returns unauthorized when URI is blank' do
      request.headers['X-Original-URI'] = ''
      get :verify
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized when timestamp is expired' do
      old_expires = 6.minutes.ago.to_i
      old_digest = Zammad.digest_string(
        Zammad::ZAMMAD_HOST,
        email,
        old_expires,
        encoded_first_name,
        encoded_last_name
      )
      old_token = OpenSSL::HMAC.hexdigest('SHA256', Zammad::ZAMMAD_SECRET, old_digest)
      old_query = "email=#{CGI.escape(email)}&expires=#{old_expires}&fn=#{encoded_first_name}&ln=#{encoded_last_name}&token=#{old_token}"
      request.headers['X-Original-URI'] = "https://#{Zammad::ZAMMAD_HOST}/auth/sso?#{old_query}"

      get :verify
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized when token is invalid' do
      bad_token = 'bad_token'
      bad_query = "email=#{CGI.escape(email)}&expires=#{expires}&fn=#{encoded_first_name}&ln=#{encoded_last_name}&token=#{bad_token}"
      request.headers['X-Original-URI'] = "https://#{Zammad::ZAMMAD_HOST}/auth/sso?#{bad_query}"

      get :verify
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized when user does not exist' do
      get :verify
      expect(response).to have_http_status(:unauthorized)
    end

    context 'with valid parameters and existing user' do
      before { account } # Create the account

      it 'returns success and sets all forwarded headers' do
        get :verify
        expect(response).to have_http_status(:ok)
        expect(response.headers['X-Forwarded-User']).to eq(email)
        expect(response.headers['X-Forwarded-First-Name']).to eq(first_name)
        expect(response.headers['X-Forwarded-Last-Name']).to eq(last_name)
      end
    end
  end
end
