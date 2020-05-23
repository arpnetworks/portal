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

  context 'handling POST /accounts/1/ssh_keys' do
    before do
      @account = mock_login!
    end

    def do_post(opts = {})
      opts[:ssh_key] = {}
      opts[:ssh_key][:name] ||= @key_name
      opts[:ssh_key][:key] ||= @key

      post :create, { account_id: @account.id }.merge(opts)
    end

    context 'with JSON' do
      before do
        @key_name = 'garry'
        @key = 'ssh-rsa AAA... me@example.com'
      end

      context 'with key and key name' do
        it 'should create a new SSH key' do
          mock_ssh_keys = mock_model(SshKey)
          expect(@account).to receive(:ssh_keys).and_return(mock_ssh_keys)
          expect(mock_ssh_keys).to receive(:create).with(name: @key_name,
                                                         key: @key)
          do_post(format: :json)
          expect(@response).to be_success
          expect(@response.body).to include('Success')
        end
      end

      context 'without key name' do
        before do
          @key_name = ''
        end

        it 'should not be successful' do
          do_post(format: :json)

          expect(@response).to_not be_success
        end

        it 'should return an errors object' do
          do_post(format: :json)

          json = JSON.parse(@response.body)
          expect(json['errors']).to_not be_empty
        end

        it 'should return an error on key name' do
          do_post(format: :json)

          json = JSON.parse(@response.body)
          expect(json['errors']['name']).to_not be_empty
        end
      end

      context 'without key' do
        before do
          @key = ''
        end

        it 'should not be successful' do
          do_post(format: :json)

          expect(@response).to_not be_success
        end

        it 'should return an errors object' do
          do_post(format: :json)

          json = JSON.parse(@response.body)
          expect(json['errors']).to_not be_empty
        end

        it 'should return an error on name' do
          do_post(format: :json)

          json = JSON.parse(@response.body)
          expect(json['errors']['key']).to_not be_empty
        end
      end
    end
  end
end
