class StripeSubscription
  def initialize(account)
    unless account.offload_billing?
      raise "Account ID #{account.id} (#{account.display_account_name}) not set up for offloaded billing"
    end

    @account = account
  end

  def bootstrap!
    cust = Stripe::Customer.create(name: @account.display_account_name,
                                   description: @account.display_account_name)
    @account.stripe_customer_id = cust.id
    @account.save
  end

  # Adds this service to the customer's subscription in Stripe
  def add!(service, opts = {})
    opts[:quantity] ||= service.stripe_quantity

    if current_subscription.nil?
      add_service_to_new_subscription!(service, opts)
    else
      add_service_to_subscription!(service, current_subscription, opts)
    end
  end

  def remove!(service, opts = {})
    opts[:quantity] ||= service.stripe_quantity

    if service.stripe_subscription_item_id.empty? &&
       service.stripe_price_id.empty?
      # Nothing we can do if these are both empty, so save us the Stripe API
      # call by quitting right now...
      return
    end

    if service.stripe_subscription_item_id.present?
      remove_by_subscription_item!(service, opts[:quantity])
    else
      # If we don't know the SubscriptionItem ID, then iterate through the whole
      # subscription, looking for a matching Price ID.  If we have a hit, then
      # steal the SubscriptionItem ID from that record and proceed normally.
      subscription_line_items(current_subscription).each do |si|
        price_id = si['price']['id']
        next unless service.stripe_price_id == price_id

        service.stripe_subscription_item_id = si['id']
        remove_by_subscription_item!(service, opts[:quantity])
      end
    end
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

  def remove_by_subscription_item!(service, quantity)
    si_id = service.stripe_subscription_item_id

    ss = Stripe::SubscriptionItem.retrieve(si_id)

    old_quantity = ss['quantity']
    new_quantity = old_quantity - quantity

    if new_quantity > 0
      Stripe::SubscriptionItem.update(si_id, quantity: new_quantity)
    else
      Stripe::SubscriptionItem.delete(si_id)
    end
  end

  def first_subscription_item(subscription)
    subscription_line_items(subscription).first
  end

  def subscription_line_items(subscription)
    subscription['items']['data']
  end
end
