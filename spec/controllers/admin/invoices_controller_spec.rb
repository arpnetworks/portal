require 'rails_helper'

describe Admin::InvoicesController do
  before do
    @admin = create_admin!
    sign_in @admin
  end

  def mock_invoice(stubs = {})
    @mock_invoice ||= mock_model(Invoice, stubs)
  end
end
