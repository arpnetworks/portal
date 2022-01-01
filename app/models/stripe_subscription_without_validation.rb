class StripeSubscriptionWithoutValidation < StripeSubscription
  def initialize(account)
    @account = account
  end
end
