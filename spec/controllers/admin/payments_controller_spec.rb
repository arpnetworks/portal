require 'rails_helper'

describe Admin::PaymentsController do
  before do
    @admin = create_admin!
    sign_in @admin
  end

  def mock_payment(stubs = {})
    @mock_invoice ||= mock_model(Payment, stubs)
  end

  describe 'handling GET /admin/invoice/1/payments/new' do
    def do_get(opts = {})
      get :new, params: opts
    end

    context 'with invoice' do
      before :each do
        @invoice = mock_model(Invoice)
        allow(Invoice).to receive(:find).with(@invoice.id.to_s).and_return @invoice
      end

      it 'should generate new invoice payment with our invoice' do
        @payments = double(:payments)
        @payment = mock_model(Payment)
        expect(@invoice).to receive(:payments).and_return @payments
        expect(@payments).to receive(:new) { @payment }
        expect(@payment).to receive(:date=).with(Date.today)

        do_get(invoice_id: @invoice.id)

        expect(response).to be_successful
        expect(assigns(:invoice).id).to eq @invoice.id
      end
    end

    context 'when invoice not found' do
      before :each do
        allow(Invoice).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'should redirect to the invoices' do
        do_get(invoice_id: 999)
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(admin_invoices_path)
      end
    end
  end

  describe 'handling POST /admin/invoice/1/payments' do
    def do_post(opts = {})
      post :create, params: opts
    end

    context 'with invoice' do
      before :each do
        @invoice = mock_model(Invoice)
        allow(Invoice).to receive(:find).with(@invoice.id.to_s).and_return @invoice

        @payments = double(:payments)
        @payment = mock_model(Payment)
        allow(@invoice).to receive(:payments).and_return @payments
        allow(@payments).to receive(:new) { @payment }
        allow(@payment).to receive(:account_id=).with(@invoice.account_id)
      end

      context 'with valid parameters' do
        before :each do
          allow(@payment).to receive(:save!).and_return true
          allow(@invoice).to receive(:balance)
        end

        it 'should create payment and assign to invoice' do
          expect(@payments).to receive(:<<).with(@payment)
          do_post(invoice_id: @invoice.id, payment: { date: '2022-01-01', amount: 10.00 })
          expect(flash[:notice]).to eq 'New payment saved'
          expect(response).to redirect_to(admin_invoice_path(@invoice))
        end
      end

      context 'with invalid parameters' do
        before :each do
          allow(@payment).to receive(:save!).and_raise ActiveRecord::RecordInvalid
        end

        it 'should render back to edit screen' do
          do_post(invoice_id: @invoice.id, payment: { date: '2022-01-01' })
          expect(response).to render_template('admin/payments/new')
        end
      end
    end
  end
end
