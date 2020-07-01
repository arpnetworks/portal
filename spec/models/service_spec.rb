require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

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
      expect(@service.deleted_at.strftime("%m/%d/%y %H:%M:%S")).to eql(time.strftime("%m/%d/%y %H:%M:%S"))
    end
  end
end
