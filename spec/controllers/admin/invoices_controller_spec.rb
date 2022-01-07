require 'rails_helper'

describe Admin::InvoicesController do
  before do
    @admin = create_admin!
    sign_in @admin
  end

  def mock_invoice(stubs = {})
    @mock_invoice ||= mock_model(Invoice, stubs)
  end

  describe 'handling PUT /admin/invoices/1/mark_unpaid' do
    context 'with invoice' do
      before :each do
        @invoice = mock_model(Invoice)
        allow(Invoice).to receive(:find).with(@invoice.id.to_s).and_return @invoice
      end

      it 'should mark the invoice unpaid' do
        expect(@invoice).to receive(:paid=).with(false)
        expect(@invoice).to receive(:save)

        put :mark_unpaid, params: { id: @invoice.id }

        expect(response).to redirect_to(admin_invoice_path(@invoice))
      end
    end

    context 'when invoice not found' do
      before :each do
        allow(Invoice).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'should redirect to the invoices' do
        put :mark_unpaid, params: { id: 999 }
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(admin_invoices_path)
      end
    end
  end

  describe 'handling PUT /admin/invoices/1/mark_paid' do
    context 'with invoice' do
      before :each do
        @invoice = mock_model(Invoice)
        allow(Invoice).to receive(:find).with(@invoice.id.to_s).and_return @invoice
      end

      it 'should mark the invoice paid' do
        expect(@invoice).to receive(:paid=).with(true)
        expect(@invoice).to receive(:save)

        put :mark_paid, params: { id: @invoice.id }

        expect(response).to redirect_to(admin_invoice_path(@invoice))
      end
    end

    context 'when invoice not found' do
      before :each do
        allow(Invoice).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'should redirect to the invoices' do
        put :mark_paid, params: { id: 999 }
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(admin_invoices_path)
      end
    end
  end
end
