module Stripe
  class AccountSyncJob < ApplicationJob
    queue_as :default

    def perform(account_id)
      account_id
    end
  end
end
