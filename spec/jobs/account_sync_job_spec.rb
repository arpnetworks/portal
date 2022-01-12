require 'rails_helper'

RSpec.describe Stripe::AccountSyncJob, type: :job do
  include ActiveJob::TestHelper

  context 'with Account ID' do
    before :each do
      @account = create :account
    end

    it 'should return Account ID' do
      expect(Stripe::AccountSyncJob.perform_now(@account.id)).to eq @account.id
    end
  end
end
