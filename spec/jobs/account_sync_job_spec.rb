require 'rails_helper'

RSpec.describe Stripe::AccountSyncJob, type: :job do
  include ActiveJob::TestHelper

  context 'with Account in Stripe' do
    before :each do
      @account = build :stripe_account
    end

    it 'should call sync!()' do
      stripe_account = double(:StripeAccount)
      expect(StripeAccount).to receive(:find).with(@account.stripe_customer_id) { stripe_account }
      expect(stripe_account).to receive(:sync!)

      Stripe::AccountSyncJob.perform_now(@account.stripe_customer_id)
    end
  end

  context 'without Account in Stripe' do
    before :each do
      @account = build :account
      @account.stripe_customer_id = nil
    end

    it 'should return nil' do
      expect(StripeAccount).to receive(:find).with(@account.stripe_customer_id)
      expect(Stripe::AccountSyncJob.perform_now(@account.stripe_customer_id)).to eq nil
    end
  end
end
