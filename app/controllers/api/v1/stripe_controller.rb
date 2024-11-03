class Api::V1::StripeController < ApiController
  skip_before_action :verify_authenticity_token, only: [:webhook, :create_setup_intent]
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
      error = "⚠️  Webhook signature verification failed. #{e.message})"
      Mailer.simple_notification(error, payload).deliver_later rescue nil
      render json: { error: error }, status: 400
      return
    rescue JSON::ParserError => e
      error = "⚠️  Webhook error while parsing basic request. #{e.message})"
      Mailer.simple_notification(error, payload).deliver_later rescue nil
      render json: { error: error }, status: 400
      return
    end

    begin
      StripeEvent.process!(event, payload)
    rescue ArgumentError => e
      Mailer.simple_notification("Received ArgumentError processing Stripe event: " + e.message, payload).deliver_later rescue nil
    rescue StandardError => e
      Mailer.simple_notification("Received StandardError processing Stripe event: " + e.message, payload).deliver_later rescue nil
    end

    render json: {}, status: 200
  end

  def create_setup_intent
    intent = Stripe::SetupIntent.create({
      automatic_payment_methods: { enabled: true },
    })

    render json: { client_secret: intent.client_secret }
  end

  protected

  def setup
    Stripe.api_key = $STRIPE_API_KEY
    @endpoint_secret = $STRIPE_ENDPOINT_SECRET
  end
end
