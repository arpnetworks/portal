require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe StripeInvoice, type: :model do
  describe 'self.create_for_account()' do
    context 'with account and invoice' do
      before :each do
        @account = build(:account)
        @stripe_event = build(:stripe_event, :invoice_finalized)
        @stripe_invoice = JSON.parse(@stripe_event.body)['data']['object']
        @inv = mock_model Invoice
      end

      it 'should create invoice for customer' do
        expect(StripeInvoice).to receive(:create).with(account: @account,
                                                       stripe_invoice_id: @stripe_invoice['id']).and_return(@inv)
        expect(@inv).to receive(:create_line_items).with(@stripe_invoice['lines']['data'])
        StripeInvoice.create_for_account(@account, @stripe_invoice)
      end
    end
  end

  describe 'create_line_items()' do
    context 'with invoice' do
      before :each do
        @inv = StripeInvoice.new
      end

      context 'with line items' do
        before :each do
          @stripe_event = build(:stripe_event, :invoice_finalized)
          @stripe_invoice = JSON.parse(@stripe_event.body)['data']['object']
          @stripe_line_items = @stripe_invoice['lines']['data']
          @first_stripe_line_item = @stripe_line_items.first
          @inv_line_item = mock_model InvoicesLineItem
          allow(@inv).to receive(:line_items).and_return(@inv_line_item)
        end

        context 'with metadata' do
          it 'should create line items with code in metadata' do
            @code = 'VPS'
            @prod = double(:stripe_product)
            @metadata = double(:metadata, product_code: @code)

            allow(Stripe::Product).to receive(:retrieve)\
              .with(id: @first_stripe_line_item['price']['product']).and_return @prod
            allow(@prod).to receive(:metadata).and_return @metadata

            expect(@inv_line_item).to receive(:create).with(
              code: @code,
              description: @first_stripe_line_item['description'],
              amount: @first_stripe_line_item['amount'] / 100
            )

            @inv.create_line_items(@stripe_line_items)
          end
        end

        context 'without metadata' do
          before :each do
            allow(Stripe::Product).to receive(:retrieve).and_raise StandardError
          end

          it 'should create line items with MISC code' do
            expect(@inv_line_item).to receive(:create).with(
              code: 'MISC',
              description: @first_stripe_line_item['description'],
              amount: @first_stripe_line_item['amount'] / 100
            )

            @inv.create_line_items(@stripe_line_items)
          end
        end
      end
    end
  end
end
