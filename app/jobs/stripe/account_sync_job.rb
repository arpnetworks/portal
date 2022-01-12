module Stripe
  class AccountSyncJob < ApplicationJob
    queue_as :default

    def perform(stripe_customer_id)
      account = StripeAccount.find(stripe_customer_id)
      return if account.nil?

      account.sync!
    end
  end
end
