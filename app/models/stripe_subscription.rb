class StripeSubscription
  def initialize(account, opts = {})
    opts[:skip_validation] ||= false

    if !opts[:skip_validation] && !account.offload_billing?
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
  def add!(service, opts = {})
    opts[:quantity] ||= 1

    if current_subscription.nil?
      add_service_to_new_subscription!(service, opts)
    else
      add_service_to_subscription!(service, current_subscription, opts)
    end
  end

  def remove!(service, opts = {})
    opts[:quantity] ||= 1

    # Notes
    #
    # If a quantity goes down to zero, we should SubscriptionItem.delete() it
  end

  # We assume only one subscription per customer, so, return the first one
  def current_subscription
    subscriptions = Stripe::Subscription.list(customer: @account.stripe_customer_id)
    subscriptions.data.first
  end

  protected

  def add_service_to_new_subscription!(service, opts)
    ss = Stripe::Subscription\
         .create(customer: @account.stripe_customer_id,
                 items: [{
                   price: service.stripe_price_id,
                   quantity: opts[:quantity],
                   metadata: {
                     link_to_service_id: service.id
                   }
                 }])

    service.stripe_subscription_item_id = first_subscription_item(ss).id
    service.save
  end

  def add_service_to_subscription!(service, subscription, opts)
    @pending_update = nil

    # Iterate through existing subscription items to see if an item already exists of the same
    # type that we are trying to add
    subscription_line_items(subscription).each do |si|
      price_id = si['price']['id']
      quantity = si['quantity']

      next unless service.stripe_price_id == price_id

      @pending_update = {
        subscription_item: si,
        quantity: quantity
      }

      break
    end

    si = if @pending_update
           new_quantity = @pending_update[:quantity] + opts[:quantity]

           # This type of item is already in this subscription, so we just need to
           # update the quantity
           Stripe::SubscriptionItem\
             .update(@pending_update[:subscription_item]['id'],
                     quantity: new_quantity)
         else
           # Otherwise, create a new line item for this subscription
           Stripe::SubscriptionItem\
             .create({
                       subscription: subscription['id'],
                       price: service.stripe_price_id,
                       quantity: opts[:quantity],
                       metadata: {
                         link_to_service_id: service.id
                       }
                     })
         end

    service.stripe_subscription_item_id = si['id']
    service.save
  end

  def first_subscription_item(subscription)
    subscription_line_items(subscription).first
  end

  def subscription_line_items(subscription)
    subscription['items']['data']
  end
end
