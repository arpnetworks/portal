require 'rails_helper'

RSpec.describe 'StripeAccount', type: :model do
  describe 'self.find()' do
    context 'with ID' do
      before :each do
        @stripe_customer_id = 'cus_foobar'
      end

      it 'should find record by stripe_customer_id' do
        expect(StripeAccount).to receive(:find_by).with(stripe_customer_id: @stripe_customer_id)
        StripeAccount.find @stripe_customer_id
      end
    end
  end

  describe 'sync!()' do
    context 'with account' do
      before :each do
        @account = build :stripe_account
      end

      it 'should update Stripe description with display account name, and update address' do
        expect(Stripe::Customer).to receive(:update)\
          .with(@account.stripe_customer_id, {
                  description: @account.display_account_name,
                  address: {
                    line1: @account.address1,
                    line2: @account.address2,
                    city: @account.city,
                    state: @account.state,
                    postal_code: @account.zip,
                    country: @account.country
                  }
                })

        @account.sync!
      end
    end
  end
end
