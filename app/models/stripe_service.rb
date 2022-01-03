# Our Service model, but with enhancements from Stripe
class StripeService < Service
  scope :dangling, -> { where("stripe_price_id != '' and stripe_subscription_item_id = ''") }
end
