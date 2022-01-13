module Stripe
  class EventProcessorJob < ApplicationJob
    queue_as :default

    def perform(id)
      stripe_event = StripeEvent.find(id)
      stripe_event.go!
    end
  end
end
