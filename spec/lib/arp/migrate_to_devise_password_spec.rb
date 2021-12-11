require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe MigrateToDevisePassword do

  fixtures :accounts

  let(:garry) { accounts(:garry) }

  it "garry is an user that hasn't migrated to Devise" do
    expect(garry.encrypted_password).to eq("")
    expect(garry.valid_password?('12345678')).to eq(false)
  end

  context 'when params is nil' do
    let(:params) { nil }

    it "won't update encrypted_password" do
      expect {
        Account.migrate_to_devise_password!(params)
      }.not_to change{ garry.reload.encrypted_password }
    end
  end

  context 'when params is not nil' do
    context 'and params[:login] is invlid' do
      let(:params) { { login: 'garrrrry', password: '12345678' } }

      it "won't update encrypted_password" do
        expect {
          Account.migrate_to_devise_password!(params)
        }.not_to change{ garry.reload.encrypted_password }
      end
    end

    context 'and params[:login] is correct' do
      context 'but params[:password] is invalid' do
        let(:params) { { login: 'garry', password: 'wrong-password' } }

        it "won't update encrypted_password" do
          expect {
            Account.migrate_to_devise_password!(params)
          }.not_to change{ garry.reload.encrypted_password }
        end
      end

      context 'and params[:password] is correct' do
        let(:params) { {login: 'garry', password: '12345678'} }

        it 'will change Account#encrypted_password' do
          expect {
            Account.migrate_to_devise_password!(params)
          }.to change{ garry.reload.encrypted_password }
          expect(garry.valid_password?('12345678')).to eq(true)
        end
      end
    end
  end

end
