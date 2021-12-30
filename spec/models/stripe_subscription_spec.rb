require 'rails_helper'

RSpec.describe StripeSubscription, type: :model do
  context 'with account' do
    before :each do
      @account = build :account
      @account.stripe_customer_id = 'cus_foo'
    end

    describe 'initialize()' do
      context 'when account does not satisfy offloaded billing requirements' do
        before :each do
          allow(@account).to receive(:offload_billing?).and_return false
        end

        it 'should raise error' do
          expect do
            StripeSubscription.new(@account)
          end.to raise_error StandardError, /account .* not set up for offloaded billing/i
        end
      end
    end

    describe 'add!()' do
      before :each do
        allow(@account).to receive(:offload_billing?).and_return true
        @ss = StripeSubscription.new(@account)
        @service = build :service
        @service.stripe_price_id = 'price_foobar'
      end

      context 'when account has no prior subscription' do
        before :each do
          allow(@ss).to receive(:current_subscription).and_return nil
        end

        it 'should create a subscription and save subscription item ID' do
          @new_stripe_sub = double(Stripe::Subscription)
          @new_stripe_sub_item = double(Stripe::SubscriptionItem, id: 'si_foo')

          expect(Stripe::Subscription).to \
            receive(:create).with(customer: @account.stripe_customer_id,
                                  items: [{
                                    price: @service.stripe_price_id,
                                    metadata: {
                                      link_to_service_id: @service.id
                                    }
                                  }]).and_return @new_stripe_sub

          expect(@ss).to \
            receive(:first_subscription_item).with(@new_stripe_sub)\
                                             .and_return @new_stripe_sub_item

          expect(@service).to receive(:stripe_subscription_item_id=).with('si_foo')
          expect(@service).to receive(:save)

          @ss.add!(@service)
        end
      end

      context 'with a prior subscription' do
        context 'and no item like this is in the current subscription' do
          before :each do
            # TODO
          end

          it 'should add it to the current subscription'
        end

        context 'and an existing item like this is already in the current subscription' do
          before :each do
            # TODO
          end

          it 'should raise the quantity of the same item within the current subscription'
        end
      end
    end

    describe 'current_subscription()' do
      before :each do
        allow(@account).to receive(:offload_billing?).and_return true
        @ss = StripeSubscription.new(@account)
      end

      it 'should list Stripe subscriptions and return first one' do
        @stripe_sub = double(Stripe::Subscription)
        @stripe_subs = double(Stripe::ListObject, data: [@stripe_sub])
        expect(Stripe::Subscription).to receive(:list).with(customer: @account.stripe_customer_id)\
                                                      .and_return @stripe_subs
        expect(@ss.send(:current_subscription)).to eq @stripe_sub
      end

      context 'without a prior subscription' do
        before :each do
          @stripe_subs = double(Stripe::ListObject, data: [])
          allow(Stripe::Subscription).to receive(:list).with(customer: @account.stripe_customer_id)\
                                                       .and_return @stripe_subs
        end

        it 'should return nil' do
          expect(@ss.send(:current_subscription)).to be_nil
        end
      end
    end
  end
end
