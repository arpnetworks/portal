# frozen_string_literal: true

require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

describe AccountsController do
  before(:context) do
    @user = create_user!
  end

  describe AccountsController, 'during account creation' do
    it 'should not allow periods in login name' do
      post :create, account: { login: 'foobar.baz', password: 'barbarbar',
                               password_confirmation: 'barbarbar',
                               email: 'foo@example.com' }

      expect(assigns(:account)).to_not be_valid
      expect(response).to render_template('new')
    end
  end

  describe AccountsController, 'when logging in' do
    it 'should remember the requested location in a non-logged-in state and redirect.' do
      request.session[:return_to] = 'http://www.google.com'
      post :login_attempt, account: { login: @user.login, password: 'mysecret' }
      expect(response).to redirect_to('http://www.google.com')
    end

    it 'should redirect to dashboard if already logged in' do
      login_as_user!
      get :login
      expect(response).to redirect_to(dashboard_path)
    end
  end
end

describe AccountsController do
  before(:context) do
    @user = create_user!
  end

  describe 'Edit account' do
    before do
      login!(@user.login, 'mysecret')
    end

    it 'should respond with success' do
      get :edit, id: @user.id
      expect(@response).to be_success
    end

    it 'should get account info from current logged in user' do
      get :edit, id: @user.id
      expect(assigns(:account)).to eq @user
    end

    it 'should not get account info from another user' do
      @other = create(:account_user, login: 'other')
      get :edit, id: @other.id
      expect(assigns(:account)).to_not eq @other
    end
  end

  describe 'Show account' do
    it 'should redirect to edit' do
      @user = login_as_user!
      get :show, id: @user.id
      expect(@response).to redirect_to(edit_account_path(@user))
    end
  end

  describe 'Forgot password' do
    it 'should not require login' do
      get :forgot_password
      expect(@response).to be_success
      expect(@response).to render_template('forgot_password')
    end
  end

  describe 'Provisioning Actions' do
    before do
      @account = login_as_user!
    end

    def do_get_ip_address_inventory
      get :ip_address_inventory, location: @location, format: :json
    end

    context 'with valid location' do
      before do
        @location = 'lax'
        @location_obj = Location.new(code: @location)
        allow(Location).to receive(:find_by).with(code: @location)\
                                            .and_return(@location_obj)
      end

      context 'with IPs in use' do
        before do
          @ips_in_use = ['10.0.0.2', '10.0.0.3']
          allow(@account).to receive(:ips_in_use).and_return(@ips_in_use)
        end

        it 'should mark them in use' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_in_use.size
          @ips_in_use.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['assigned']).to be true
          end
        end

        it 'should have further assignment information' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_in_use.size
          @ips_in_use.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['assignment']).not_to be_nil
            expect(ips[available_ip]['assignment']).not_to be_empty
          end
        end
      end

      context 'with IPs available' do
        before do
          @ips_available = ['10.0.0.4', '10.0.0.5', '10.0.0.6']
          allow(@account).to receive(:ips_available)\
            .with(location: @location_obj).and_return(@ips_available)
        end

        it 'should set caption for location' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          caption = json_response['caption']

          expect(caption).to match(/Please Choose/)
        end

        it 'should include IP address in hash' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_available.size
          @ips_available.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['ip_address']).to eq available_ip
          end
        end

        it 'should mark them available' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_available.size
          @ips_available.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['assigned']).to be false
          end
        end

        it 'should be assigned to the correct location' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_available.size
          @ips_available.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['location']).to eq @location
          end
        end

        it 'should not have any further assignment information' do
          do_get_ip_address_inventory
          expect(@response).to be_success

          json_response = JSON.parse(@response.body)
          ips = json_response['ips']

          expect(ips.size).to eq @ips_available.size
          @ips_available.each do |available_ip|
            expect(ips[available_ip]).not_to be_nil
            expect(ips[available_ip]['assignment']).to be_nil
          end
        end
      end
    end

    context 'with invalid location' do
      before do
        @location = 'ams'
      end

      it 'should return empty set' do
        do_get_ip_address_inventory

        expect(@response).to_not be_success
        expect(@response.body).to include('No such location')
      end
    end
  end
end
