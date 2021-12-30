class StripeSubscription
  def initialize(account)
    unless account.offload_billing?
      raise "Account ID #{account.id} (#{account.display_account_name}) not set up for offloaded billing"
    end

    @account = account
  end

  def bootstrap!
    cust = Stripe::Customer.create(name: @account.display_account_name)
    @account.stripe_customer_id = cust.id
    @account.save
  end

  # Adds this service to the customer's subscription in Stripe
  def add!(service)
    if current_subscription.nil?
      ss = Stripe::Subscription.create(customer: @account.stripe_customer_id,
                                       items: [{
                                         price: service.stripe_price_id,
                                         metadata: {
                                           link_to_service_id: service.id
                                         }
                                       }])

      service.stripe_subscription_item_id = first_subscription_item(ss).id
      service.save
    else
      # TODO: A big one!
      #
      # subscription = current
      #   for each line item
      #   (sub['items']['data'].each do |si|
      #     price = si.price.id
      #     qty   = si.quantity
      #
      #     if service.stripe_price_id == price
      #       # We have a hit!
      #
      #       # So just call
      #       Stripe::SubscriptionItem.update(si.id, quantity: qty + 1)
      #       service.stripe_subscription_item_id = si.id
      #       service.save
      #
      #       return
      #
      # Otherwise, no hit, then we create a new item:
      #
      #   Stripe::Subscription.update(sub.id, items: [{ price: service.stripe_price_id, metadata: {...} }])
      #
      #   # Difficult to pull out the si.id here, so maybe we just wait for it in the callback?
    end
  end

  def remove!(service)
    # Notes
    #
    # If a quantity goes down to zero, we should SubscriptionItem.delete() it
  end

  protected

  # We assume only one subscription per customer, so, return the first one
  def current_subscription
    subscriptions = Stripe::Subscription.list(customer: @account.stripe_customer_id)
    subscriptions.data.first
  end

  def first_subscription_item(subscription)
    subscription.items.data.first
  end
end
