require 'rails_helper'

describe Service do
  describe 'give_me_totals()' do
    it 'should add up amounts per interval' do
      @services = [create(:service, billing_amount: 100, billing_interval: 1),
                   create(:service, billing_amount: 200, billing_interval: 1),
                   create(:service, billing_amount: 700, billing_interval: 12),
                   create(:service, billing_amount: 24.95, billing_interval: 12),
                   create(:service, billing_amount: 400, billing_interval: 3)]

      @expected = { 1 => 300, 3 => 400, 12 => 724.95 }

      expect(Service.give_me_totals(@services)).to eq @expected
    end

    it 'should return empty hash if no services provided' do
      expect(Service.give_me_totals([])).to eq({})
    end

    it 'should not consider intervals less than 1' do
      @service = [Service.new(billing_amount: 50, billing_interval: 0)]
      expect(Service.give_me_totals(@service)).to eq({})
    end

    it 'should not consider an interval of nil' do
      @service = [Service.new(billing_amount: 50, billing_interval: nil)]
      expect(Service.give_me_totals(@service)).to eq({})
    end
  end

  context 'when destroying' do
    before do
      @service = create :service
    end

    # This is no longer desired.  If a service is deleted, it is flagged
    # deleted, but the record still exists.  So, resources associated with
    # that service can remain around as well.  If removing of resources is
    # desired, they should be removed manually.
    #
    # specify "should remove resources" do
    #   res = @service.resources[0]
    #   res_id = res.id
    #   res.should_not be_nil
    #   @service.destroy
    #   lambda { Resource.find(res_id) }.should \
    #     raise_error(ActiveRecord::RecordNotFound)
    # end

    context 'and offload_billing is false' do
      before :each do
        allow(@service.account).to receive(:offload_billing?).and_return false
      end

      specify 'should set deleted_at' do
        expect(@service.deleted_at).to be_nil
        @service.destroy
        expect(@service.deleted_at).to_not be_nil
      end

      specify 'should not remove record from database' do
        id = @service.id
        @service.destroy
        expect(Service.find(id)).to_not be_nil
      end

      specify 'deleted?() should be true' do
        expect(@service.deleted?).to be false
        @service.destroy
        expect(@service.deleted?).to be true
      end

      specify 'should not delete record twice' do
        time = 2.days.ago
        @service.deleted_at = time
        @service.destroy
        expect(@service.deleted_at.strftime('%m/%d/%y %H:%M:%S')).to eql(time.strftime('%m/%d/%y %H:%M:%S'))
      end
    end

    context 'and offload_billing is true' do
      before :each do
        allow(@service.account).to receive(:offload_billing?).and_return true
      end

      it 'should remove itself from the current subscription' do
        @ss =  double(StripeSubscription)
        expect(@service.account).to receive(:stripe_subscription).and_return @ss
        expect(@ss).to receive(:remove!).with(@service)
        @service.destroy
      end
    end
  end

  context 'activate_billing!()' do
    before :each do
      @service = build :service
    end

    context 'when service is pending' do
      before :each do
        @service.pending = true
      end

      it 'should flip pending to false' do
        expect(@service.pending).to eq true
        @service.activate_billing!
        expect(@service.pending).to eq false
      end

      it 'should save record' do
        expect(@service).to receive(:save)
        @service.activate_billing!
      end
    end

    context 'when account billing is offloaded' do
      before :each do
        @account = mock_model(Account)
        allow(@account).to receive(:offload_billing?).and_return true
        allow(@account).to receive(:beta_billing_exempt?).and_return false
        allow(@service).to receive(:account).and_return @account
      end

      context 'when service is pending' do
        before :each do
          @service.pending = true
        end

        it 'should add to Stripe subscription' do
          @sub = double(:stripe_subscription)
          expect(@account).to receive(:stripe_subscription).and_return @sub
          expect(@sub).to receive(:add!).with @service
          @service.activate_billing!
        end
      end

      context 'when service is no longer pending' do
        before :each do
          @service.pending = false
        end

        it 'should not add to Stripe subscription' do
          @sub = double(:stripe_subscription)
          expect(@account).to receive(:stripe_subscription).and_return @sub
          expect(@sub).to_not receive(:add!).with @service
          @service.activate_billing!
        end
      end
    end
  end
end
