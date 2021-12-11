module IntegrationSessionHelper
  def set_session(vars = {})
    post test_session_path, params: { session_vars: vars }
    expect(response).to have_http_status(:created)

    vars.each_key do |var|
      expect(session[var]).to be_present
    end
  end

  def get_session(key)
    get test_session_path(id: key, format: :json)
    expect(response).to have_http_status(:ok)

    JSON.parse(response.body)["value"]
  end
end