class Api::V1::StripeController < ApiController
  skip_before_action :verify_authenticity_token, only: [:webhook]
  before_action :setup

  def webhook
    payload = request.body.read
    event = nil

    # Retrieve the event by verifying the signature using the raw body and secret.
    signature = request.env['HTTP_STRIPE_SIGNATURE'];
    begin
      event = Stripe::Webhook.construct_event(
        payload, signature, @endpoint_secret
      )
    rescue Stripe::SignatureVerificationError => e
      simple_email("⚠️  Webhook signature verification failed. #{e.message})", payload) rescue nil
      render json: {}, status: 400
      return
    rescue JSON::ParserError => e
      simple_email("⚠️  Webhook error while parsing basic request. #{e.message})", payload) rescue nil
      render json: {}, status: 400
      return
    end

    begin
      StripeEvent.process!(event, payload)
    rescue ArgumentError => e
      simple_email("Received ArgumentError processing Stripe event: " + e.message, payload) rescue nil
    rescue StandardError => e
      simple_email("Received StandardError processing Stripe event: " + e.message, payload) rescue nil
    end

    render json: {}, status: 200
  end

  protected

  def setup
    Stripe.api_key = $STRIPE_API_KEY
    @endpoint_secret = $STRIPE_ENDPOINT_SECRET
  end
end
