require 'rails_helper'

describe Admin::InvoicesController do
  before do
    @admin = create_admin!
    sign_in @admin
  end

  def mock_invoice(stubs = {})
    @mock_invoice ||= mock_model(Invoice, stubs)
  end

  describe 'handling GET /admin/invoice/1/pay' do
    def do_get(opts = {})
      get :pay, params: opts
    end

    context 'with invoice' do
      before :each do
        @invoice = mock_model(Invoice)
        allow(Invoice).to receive(:find).with(@invoice.id.to_s).and_return @invoice
      end

      it 'should display invoice pay form with our invoice' do
        do_get(id: @invoice.id)
        expect(response).to be_successful
        expect(assigns(:invoice).id).to eq @invoice.id
      end
    end

    context 'when invoice not found' do
      before :each do
        allow(Invoice).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'should redirect to the invoices' do
        do_get(id: 999)
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(admin_invoices_path)
      end
    end
  end
end
