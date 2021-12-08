module Admin::StripeEventsHelper
  def stripe_events_colspan(admin, action_name)
    # I don't think we use this
    if action_name == 'index'
      5
    else
      4
    end
  end
end
