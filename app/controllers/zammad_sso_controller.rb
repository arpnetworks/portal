class ZammadSsoController < ApplicationController
  skip_before_action :verify_authenticity_token

  def verify
    # Get parameters from original request
    uri = request.headers['X-Original-URI']

    Rails.logger.info("[ZammadSSO] URI: #{uri}")

    return head :unauthorized if uri.blank?

    begin
      query = URI(uri).query
      Rails.logger.info("[ZammadSSO] Query string: #{query}")

      return head :unauthorized if query.blank?

      params = URI.decode_www_form(query).to_h
    rescue StandardError
      Rails.logger.error('[ZammadSSO] Error decoding query string')
      return head :unauthorized
    end

    Rails.logger.info("[ZammadSSO] Params: #{params}")

    # Verify timestamp is recent
    expires = params['expires'].to_i
    current = Time.current.to_i

    Rails.logger.info("[ZammadSSO] Expires: #{expires}, Current: #{current}")

    return head :unauthorized if current - expires > 300 # 5 minutes

    digest_string = Zammad.digest_string(Zammad::ZAMMAD_HOST, params['email'], params['expires'])

    # Verify token
    expected_token = OpenSSL::HMAC.hexdigest(
      'SHA256',
      Zammad::ZAMMAD_SECRET,
      digest_string
    )
    token = params['token']

    # Rails.logger.info("[ZammadSSO] Expected token: #{expected_token}")
    # Rails.logger.info("[ZammadSSO] Token: #{token}")

    return head :unauthorized unless secure_compare(token, expected_token)

    Rails.logger.info('[ZammadSSO] Token verified')

    # Verify user exists
    account = Account.find_by(email: params['email'])
    return head :unauthorized unless account

    Rails.logger.info("[ZammadSSO] Account: #{account.email}")

    # Set authenticated user header
    response.headers['X-Forwarded-User'] = account.email
    head :ok
  end

  private

  def secure_compare(a, b)
    ActiveSupport::SecurityUtils.secure_compare(a, b)
  end
end
