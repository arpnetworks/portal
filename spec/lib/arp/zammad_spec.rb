require 'rails_helper'

describe Zammad do
  let(:test_class) do
    Class.new do
      include Zammad
      attr_accessor :email

      def initialize(email)
        @email = email
      end
    end
  end

  let(:email) { 'test@example.com' }
  let(:instance) { test_class.new(email) }
  let(:expiry) { 5.minutes.from_now.to_i }

  describe '.digest_string' do
    it 'combines host, email and expiry with slashes' do
      result = described_class.digest_string(Zammad::ZAMMAD_HOST, email, expiry)
      expect(result).to eq("#{Zammad::ZAMMAD_HOST}/#{email}/#{expiry}")
    end
  end

  describe '#zammad_token' do
    it 'generates correct HMAC token' do
      digest_string = Zammad.digest_string(Zammad::ZAMMAD_HOST, email, expiry)
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

      it 'generates correct localhost URL' do
        allow(Account).to receive(:zammad_token_expiry_timestamp).and_return(expiry)
        url = instance.zammad_sso_url
        expect(url).to start_with('http://localhost:3000/auth/sso')
        expect(url).to include("email=#{CGI.escape(email)}")
        expect(url).to include("expires=#{expiry}")
        expect(url).to include('token=')
      end
    end

    context 'when ZAMMAD_HOST is a regular hostname' do
      before { stub_const('Zammad::ZAMMAD_HOST', 'support.example.com') }

      it 'generates correct HTTPS URL' do
        allow(Account).to receive(:zammad_token_expiry_timestamp).and_return(expiry)
        url = instance.zammad_sso_url
        expect(url).to start_with('https://support.example.com/auth/sso')
        expect(url).to include("email=#{CGI.escape(email)}")
        expect(url).to include("expires=#{expiry}")
        expect(url).to include('token=')
      end
    end
  end
end
