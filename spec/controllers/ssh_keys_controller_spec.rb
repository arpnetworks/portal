require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

describe SshKeysController do
  context 'handling GET /accounts/1/ssh_keys' do
    before do
      @account = mock_login!
    end

    def do_get(opts = {})
      get :index, params: { account_id: @account.id }.merge(opts)
    end

    context 'with JSON' do
      context 'with keys' do
        before do
          @ssh_key_1 = build(:ssh_key, name: 'foo', id: 1)
          @ssh_key_2 = build(:ssh_key, name: 'bar', id: 2)
          @ssh_keys = [@ssh_key_1, @ssh_key_2]

          allow(@account).to receive(:ssh_keys).and_return(@ssh_keys)
        end

        it 'should be a success' do
          do_get(format: :json)
          expect(response).to be_successful
        end

        it 'should return keys JSON object' do
          do_get(format: :json)

          json = JSON.parse(@response.body)
          expect(json.size).to eq 2
        end

        context 'with selected keys in session' do
          before do
            session['form'] = {
              'ssh_keys' => [@ssh_key_1.id]
            }
          end

          it 'should return keys JSON object with one selected' do
            do_get(format: :json)

            json = JSON.parse(@response.body)

            @copy = JSON.parse(@ssh_key_1.to_json)
            @copy2 = JSON.parse(@ssh_key_2.to_json)

            expect(json.include?(@copy.merge('selected' => true))).to be true
            expect(json.include?(@copy2)).to be true
            expect(json.size).to eq 2
          end
        end
      end

      context 'without keys' do
        before do
          allow(@account).to receive(:ssh_keys).and_return([])
        end

        it 'should be a success' do
          do_get(format: :json)
          expect(response).to be_successful
        end

        it 'should return empty JSON' do
          do_get(format: :json)

          json = JSON.parse(@response.body)
          expect(json).to be_empty
        end
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
      opts[:ssh_key][:username] ||= @username

      post :create, params: { account_id: @account.id }.merge(opts)
    end

    context 'with JSON' do
      before do
        @key_name = 'garry'
        @key = 'ssh-rsa AAA... me@example.com'
        @username = 'admin'
      end

      context 'with key and key name' do
        it 'should create a new SSH key and return itself' do
          @key_id = 99
          ssh_key = double(SshKey, id: @key_id, name: @key_name, username: @username)
          mock_ssh_keys = mock_model(SshKey)
          expect(@account).to receive(:ssh_keys).and_return(mock_ssh_keys)
          expect(mock_ssh_keys).to receive(:create).with(name: @key_name,
                                                         key: @key,
                                                         username: @username).and_return(ssh_key)
          do_post(format: :json)
          expect(@response).to be_successful

          json = JSON.parse(@response.body)
          expect(json['message']).to include('Success')
          expect(json['key']).to_not be_empty
          expect(json['key']['id']).to eq ssh_key.id
          expect(json['key']['name']).to eq ssh_key.name
          expect(json['key']['username']).to eq ssh_key.username
        end
      end

      context 'without key name' do
        before do
          @key_name = ''
        end

        it 'should not be successful' do
          do_post(format: :json)

          expect(@response).to_not be_successful
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

          expect(@response).to_not be_successful
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

  context 'handling DELETE /accounts/1/ssh_keys/1' do
    before do
      @account = mock_login!
      @ssh_key_id = '1'
    end

    def do_delete(opts)
      delete :destroy, params: { account_id: @account.id, id: @ssh_key_id }.merge(opts)
    end

    context 'with key' do
      before do
        @ssh_key = double(SshKey)
        mock_ssh_keys = double('mock_ssh_keys')
        allow(@account).to receive(:ssh_keys).and_return(mock_ssh_keys)
        allow(mock_ssh_keys).to receive(:find_by).with(id: @ssh_key_id).and_return(@ssh_key)
      end

      it 'should be successful' do
        allow(@ssh_key).to receive(:destroy).and_return(true)
        do_delete(format: :json)
        expect(@response).to be_successful
      end

      it 'should destroy key' do
        expect(@ssh_key).to receive(:destroy)
        do_delete(format: :json)
      end
    end

    context 'without key' do
      before do
        mock_ssh_keys = double('mock_ssh_keys')
        allow(@account).to receive(:ssh_keys).and_return(mock_ssh_keys)
        allow(mock_ssh_keys).to receive(:find_by).with(id: @ssh_key_id).and_return(nil)
      end

      it 'should not be successful' do
        do_delete(format: :json)
        expect(@response).to_not be_successful
      end
    end
  end
end
