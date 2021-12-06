class Api::V1::StripeController < ApiController
  skip_before_action :verify_authenticity_token, only: [:webhook]

  def webhook
    render plain: 'Hi!'
  end
end
