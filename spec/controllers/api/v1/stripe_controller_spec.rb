require File.expand_path(File.dirname(__FILE__) + '/../../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../arp_spec_helper')

describe Api::V1::StripeController do
  context 'handling POST /api/v1/stripe/webhook' do
    def do_post(opts = {})
      post :webhook, params: { }.merge(opts)
    end

    context 'with valid payload' do
      it 'should return 200'
    end

    context 'with invalid payload' do
      it 'should return 400'
    end
  end
end
