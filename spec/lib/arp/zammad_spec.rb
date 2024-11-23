require 'rails_helper'

describe Zammad do
  let(:test_class) do
    Class.new do
      include Zammad
      attr_accessor :email, :first_name, :last_name

      def initialize(email, first_name = 'Test', last_name = 'User')
        @email = email
        @first_name = first_name
        @last_name = last_name
      end
    end
  end

  let(:email) { 'test@example.com' }
  let(:first_name) { 'Test' }
  let(:last_name) { 'User' }
  let(:instance) { test_class.new(email, first_name, last_name) }
  let(:expiry) { 5.minutes.from_now.to_i }

  describe '.digest_string' do
    it 'combines all components with pipe delimiter' do
      encoded_first_name = Base64.strict_encode64(first_name)
      encoded_last_name = Base64.strict_encode64(last_name)

      result = described_class.digest_string(
        Zammad::ZAMMAD_HOST,
        email,
        expiry,
        encoded_first_name,
        encoded_last_name
      )

      expected = [
        Zammad::ZAMMAD_HOST,
        email,
        expiry.to_s,
        encoded_first_name,
        encoded_last_name
      ].join('|')

      expect(result).to eq(expected)
    end
  end

  describe '#zammad_token' do
    it 'generates correct HMAC token with encoded names' do
      encoded_first_name = Base64.strict_encode64(first_name)
      encoded_last_name = Base64.strict_encode64(last_name)

      digest_string = Zammad.digest_string(
        Zammad::ZAMMAD_HOST,
        email,
        expiry,
        encoded_first_name,
        encoded_last_name
      )

      expected_token = OpenSSL::HMAC.hexdigest('SHA256', Zammad::ZAMMAD_SECRET, digest_string)
      expect(instance.zammad_token(expiry)).to eq(expected_token)
    end
  end

  describe '#zammad_sso_url' do
    context 'when ZAMMAD_HOST is blank' do
      before { stub_const('Zammad::ZAMMAD_HOST', '') }

      it 'returns empty string' do
        expect(instance.zammad_sso_url).to eq('')
      end
    end

    context 'when ZAMMAD_HOST is localhost' do
      before { stub_const('Zammad::ZAMMAD_HOST', 'localhost') }

      it 'generates correct localhost URL with encoded names' do
        allow(Account).to receive(:zammad_token_expiry_timestamp).and_return(expiry)
        url = instance.zammad_sso_url

        expect(url).to start_with('http://localhost:3000/auth/sso')
        expect(url).to include("email=#{CGI.escape(email)}")
        expect(url).to include("expires=#{expiry}")
        expect(url).to include("fn=#{Base64.strict_encode64(first_name)}")
        expect(url).to include("ln=#{Base64.strict_encode64(last_name)}")
        expect(url).to include('token=')
      end
    end

    context 'when ZAMMAD_HOST is a regular hostname' do
      before { stub_const('Zammad::ZAMMAD_HOST', 'support.example.com') }

      it 'generates correct HTTPS URL with encoded names' do
        allow(Account).to receive(:zammad_token_expiry_timestamp).and_return(expiry)
        url = instance.zammad_sso_url

        expect(url).to start_with('https://support.example.com/auth/sso')
        expect(url).to include("email=#{CGI.escape(email)}")
        expect(url).to include("expires=#{expiry}")
        expect(url).to include("fn=#{Base64.strict_encode64(first_name)}")
        expect(url).to include("ln=#{Base64.strict_encode64(last_name)}")
        expect(url).to include('token=')
      end
    end
  end
end
