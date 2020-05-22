require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

describe SshKeysController do
  context 'handling GET /accounts/1/ssh_keys' do
    before do
      @account = mock_login!
    end

    def do_get(opts = {})
      get :index, { account_id: @account.id }.merge(opts)
    end

    context 'with JSON' do
      it 'should be a success' do
        do_get(format: :json)
        expect(response).to be_success
      end
    end
  end

  context 'create()' do
    def do_create(opts = {})
      post :create, { account_id: @account.id }.merge(opts)
    end
  end
end
