require 'rails_helper'

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

  describe 'self.link_to_invoice()' do
    context 'with Stripe invoice' do
      before :each do
        @stripe_event = build(:stripe_event, :invoice_finalized)
        @stripe_invoice = JSON.parse(@stripe_event.body)['data']['object']
        @stripe_invoice_id = @stripe_invoice['id']
      end

      context 'with invoice ID' do
        before :each do
          @invoice_id = 123
        end

        context 'and invoice exists' do
          before :each do
            @invoice = mock_model Invoice
            allow(Invoice).to receive(:find).with(@invoice_id).and_return @invoice
          end

          it 'should link the Stripe invoice to our invoice' do
            expect(@invoice).to receive(:stripe_invoice_id=).with @stripe_invoice_id
            expect(@invoice).to receive(:save)
            StripeInvoice.link_to_invoice(@invoice_id, @stripe_invoice)
          end
        end

        context 'and invoice does not exist' do
          before :each do
            allow(Invoice).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
          end

          it 'should raise error' do
            expect { StripeInvoice.link_to_invoice(999, @stripe_invoice) }.to raise_error ArgumentError
          end
        end
      end
    end
  end

  describe 'self.create_payment()' do
    context 'with account and invoice' do
      before :each do
        @account = build(:account)
        @stripe_event = build(:stripe_event, :invoice_paid)
        @stripe_invoice = JSON.parse(@stripe_event.body)['data']['object']
        @inv = mock_model Invoice
      end

      it 'should create payment for invoice and mark it paid' do
        payments = double :payments

        allow(Invoice).to receive(:find_by).with(stripe_invoice_id: @stripe_invoice['id'])\
                                           .and_return(@inv)
        allow(@inv).to receive(:payments).and_return payments

        expect(payments).to receive(:create).with(
          account: @account,
          reference_number: '',
          date: Time.at(@stripe_invoice['status_transitions']['paid_at']),
          method: 'Stripe',
          amount: @stripe_invoice['total'] / 100
        )
        expect(@inv).to receive('paid=').with(true)
        expect(@inv).to receive('save')

        StripeInvoice.create_payment(@account, @stripe_invoice)
      end

      context 'when Invoice not found' do
        before :each do
          allow(Invoice).to receive(:find).and_return nil
        end

        it 'should raise error' do
          expect { StripeInvoice.create_payment(@account, @stripe_invoice) }.to raise_error StandardError, /not found/
        end
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

  describe 'create_discount_line_items()' do
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

        context 'with discount amounts' do
          before :each do
            @discount_amounts = []

            # This turns the keys into symbols, sigh...
            # @discount_amounts << {
            #   'amount': 100,
            #   'discount': 'di_1KAWWk2LsKuf8PTnjxDserXo'
            # }
            #
            # Must do it like this, wtf:
            @discount_amounts[0] = {}
            @discount_amounts[0]['amount'] = 100
            @discount_amounts[0]['discount'] = 'di_1KAWWk2LsKuf8PTnjxDserXo'
          end

          it 'should create line items with negative amount (discount)' do
            @code = 'VPS'

            expect(@inv_line_item).to receive(:create).with(code: @code, amount: -1.00, description: 'Discount')
            @inv.create_discount_line_items(@code, @discount_amounts)
          end
        end
      end
    end
  end
end
