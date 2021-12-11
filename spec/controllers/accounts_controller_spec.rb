# frozen_string_literal: true
require 'rails_helper'

describe AccountsController do
  before(:context) do
    @user = create_user!
  end

  describe 'Edit account' do
    before do
      sign_in @user
    end

    it 'should respond with success' do
      get :edit, params: { id: @user.id }
      expect(@response).to be_successful
    end

    it 'should get account info from current logged in user' do
      get :edit, params: { id: @user.id }
      expect(assigns(:account)).to eq @user
    end

    it 'should not get account info from another user' do
      @other = create(:account_user, login: 'other')
      get :edit, params: { id: @other.id }
      expect(assigns(:account)).to_not eq @other
    end
  end

  describe 'Show account' do
    it 'should redirect to edit' do
      sign_in @user
      get :show, params: { id: @user.id }
      expect(@response).to redirect_to(edit_account_path(@user))
    end
  end

  describe 'Provisioning Actions' do
    before do
      @account = @user
      sign_in @account
    end

    def do_get_ip_address_inventory
      get :ip_address_inventory, params: { location: @location, format: :json }
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
          allow_any_instance_of(Account).to receive(:ips_in_use).and_return(@ips_in_use)
        end

        it 'should mark them in use' do
          do_get_ip_address_inventory
          expect(@response).to be_successful

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
          expect(@response).to be_successful

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
          allow_any_instance_of(Account).to receive(:ips_available)\
            .with(location: @location_obj).and_return(@ips_available)
        end

        it 'should set caption for location' do
          do_get_ip_address_inventory
          expect(@response).to be_successful

          json_response = JSON.parse(@response.body)
          caption = json_response['caption']

          expect(caption).to match(/Please Choose/)
        end

        it 'should include IP address in hash' do
          do_get_ip_address_inventory
          expect(@response).to be_successful

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
          expect(@response).to be_successful

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
          expect(@response).to be_successful

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
          expect(@response).to be_successful

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

        expect(@response).to_not be_successful
        expect(@response.body).to include('No such location')
      end
    end
  end
end
