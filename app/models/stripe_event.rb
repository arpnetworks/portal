class StripeEvent < ApplicationRecord
  def supported_events
    %w(
      invoice.finalized
    )
  end

  def go!
    raise StandardError.new('Attempt to handle event already processed') if processed?
    raise ArgumentError.new("Unsupported event '#{event_type}") unless supported_events.include?(event_type)

    begin
      handler = "handle_" + event_type.gsub('.', '_') + "!"
      send(handler)
    rescue NoMethodError => e
      raise ArgumentError.new("No handler found for event '#{event_type}'")
    end
  end

  def processed?
    status == 'processed'
  end

  def self.process!(event, payload)
    stripe_event = StripeEvent.create(
      event_id: event.id, event_type: event.type, status: 'received', body: payload
    )
    stripe_event.go!
  end

  ##################
  # EVENT HANDLERS #
  ##################

  def handle_invoice_finalized!

  end
end
