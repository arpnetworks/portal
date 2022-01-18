module Admin::StripeEventsHelper
  def stripe_events_related(stripe_event)
    case stripe_event.event_type
    when 'payment_method.attached', 'invoice.finalized', 'invoice.paid', 'invoice.payment_failed', 'invoice.payment_action_required', 'charge.refunded',
         'customer.subscription.created'
      account = stripe_event.related(:account)
      account ? link_to(h(account.display_account_name), admin_account_path(account)) : ''
    else
      ''
    end
  end
end
