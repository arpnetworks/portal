require 'rails_helper'

describe CreditCardsController do
  before do
    @account = create :account_user, first_name: 'John', last_name: 'Doe'

    sign_in @account

    # Don't actually run the bootstrap_stripe! part
    allow(controller).to receive(:current_account).and_return @account
    allow(@account).to receive(:bootstrap_stripe!).and_return nil
  end

  describe 'handling GET /account/1/credit_cards/new' do
    def do_get(opts = {})
      get :new, params: { account_id: @account.id }.merge(opts)
    end

    it 'should assign new credit card record' do
      do_get
      expect(assigns(:credit_card)).to be_new_record
    end

    it 'should be successful' do
      do_get
      expect(response).to be_successful
    end

    it 'should pre-fill Name of Card field with account full name' do
      do_get
      expect(assigns(:credit_card).first_name).to eq 'John Doe'
    end

    context 'when account is in Stripe' do
      before :each do
        @stripe_customer_id = 'cust_123'
        allow(@account).to receive(:in_stripe?).and_return true
        allow(@account).to receive(:stripe_customer_id).and_return @stripe_customer_id
      end

      it 'should create a SetupIntent' do
        @our_stripe_subscription = double(StripeSubscription)
        allow(StripeSubscriptionWithoutValidation).to receive(:new)\
          .with(@account)\
          .and_return(@our_stripe_subscription)

        expect(@our_stripe_subscription).to receive(:create_setup_intent!)
        do_get
      end
    end
  end

  describe 'handling POST /account/1/credit_cards' do
    before do
      @credit_card = {
        'number' => '4111111111111111',
        'month' => 0o4,
        'year' => 2014,
        'first_name' => 'John',
        'last_name' => 'Doe'
      }
    end

    def do_post(opts = {})
      post :create, params: { account_id: @account.id }.merge(opts)
    end

    context 'with new credit card' do
      before do
        @credit_card_mock = mock_model(CreditCard,
                                       number: '41111')
        expect(CreditCard).to receive(:new) { @credit_card_mock }
      end

      context 'assigned to account' do
        before do
          expect(@credit_card_mock).to receive(:account_id=).with(@account.id)
        end

        context 'with valid credit_card' do
          before do
            expect(@credit_card_mock).to receive(:save).and_return(true)
            expect(@credit_card_mock).to receive(:valid?).and_return(true)
          end

          it 'should assign credit_card to account' do
            do_post(credit_card: @credit_card)
          end

          it 'should assign flash informational message' do
            do_post(credit_card: @credit_card)
            expect(flash[:notice]).to_not be_nil
          end

          it 'should redirect to dashboard' do
            do_post(credit_card: @credit_card)
            expect(response).to redirect_to(dashboard_path)
          end
        end

        context 'without valid credit_card' do
          before do
            expect(@credit_card_mock).to receive(:save).and_return(false)
            expect(@credit_card_mock).to receive(:valid?).and_return(false)
          end

          it 'should render new credit card form' do
            do_post(credit_card: @credit_card)
            expect(response).to render_template('credit_cards/new')
          end
        end
      end
    end
  end
end
