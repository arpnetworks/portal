require 'rails_helper'

RSpec.describe Stripe::EventProcessorJob, type: :job do
  include ActiveJob::TestHelper

  context 'with Stripe Event' do
    before :each do
      @event = mock_model(StripeEvent)
    end

    it 'should find event and run go!()' do
      expect(StripeEvent).to receive(:find).with(@event.id).and_return @event
      expect(@event).to receive(:go!)

      Stripe::EventProcessorJob.perform_now(@event.id)
    end
  end
end
