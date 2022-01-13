require 'rails_helper'
require 'stripe_helper'

RSpec.describe StripeEvent, type: :model do
  context 'with event' do
    before :each do
      @stripe_event = StripeEvent.new
    end

    describe 'go!()' do
      context 'with event' do
        context 'with status: processed' do
          before :each do
            @stripe_event.status = 'processed'
          end

          it 'should raise error' do
            expect { @stripe_event.go! }.to raise_error StandardError, /Attempt to handle event already processed/
          end
        end

        context 'with status: received' do
          before :each do
            @stripe_event.status = 'received'
          end

          context 'with event_type invoice.finalized' do
            before :each do
              @stripe_event.event_type = 'invoice.finalized'
            end

            it 'should call proper event handler' do
              expect(@stripe_event).to receive('handle_invoice_finalized!')
              @stripe_event.go!
            end

            it 'should mark event as processed' do
              allow(@stripe_event).to receive('handle_invoice_finalized!')
              expect(@stripe_event).to receive(:handled!)
              @stripe_event.go!
            end
          end

          context 'with event_type bogus_event' do
            before :each do
              @stripe_event.event_type = 'bogus.event'
            end

            it 'should raise error' do
              expect { @stripe_event.go! }.to raise_error ArgumentError, /Unsupported event/
            end
          end
        end
      end
    end

    describe 'processed?()' do
      context 'when event status is empty' do
        before :each do
          @stripe_event.status = ''
        end

        it 'should return false' do
          expect(@stripe_event.processed?).to eq false
        end
      end

      context 'when event status is nil' do
        before :each do
          @stripe_event.status = nil
        end

        it 'should return false' do
          expect(@stripe_event.processed?).to eq false
        end
      end

      context 'when event status is processed' do
        before :each do
          @stripe_event.status = 'processed'
        end

        it 'should return true' do
          expect(@stripe_event.processed?).to eq true
        end
      end
    end

    describe 'handled!()' do
      context 'with received event' do
        before :each do
          @stripe_event.status = 'received'
        end

        it 'should set status to processed' do
          @stripe_event.handled!
          expect(@stripe_event.processed?).to eq true
        end
      end
    end

    describe 'related()' do
      context 'with event' do
        before :each do
          # We use invoice_finalized as an example, but could be any stripe_event
          @stripe_event = build(:stripe_event, :invoice_finalized)
          @invoice = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with nothing' do
          before :each do
            @desired_model = nil
          end

          it 'should return nil' do
            expect(@stripe_event.related(@desired_model)).to be_nil
          end
        end

        context 'with :account' do
          before :each do
            @desired_model = :account
            @account = mock_model(Account)
          end

          context 'and an account is associated with the Stripe event' do
            it 'should return account model' do
              allow(@stripe_event).to receive(:get_account_and_invoice).and_return @account
              expect(@stripe_event.related(@desired_model)).to eq @account
            end
          end

          context 'and an account is not associated with the Stripe event' do
            before :each do
              allow(@stripe_event).to receive(:get_account_and_invoice).and_raise StandardError
            end

            it 'should return nil' do
              expect(@stripe_event.related(@desired_model)).to be_nil
            end
          end
        end

        context 'with :invoice' do
          before :each do
            @desired_model = :invoice
            @invoice = mock_model(Invoice)
          end

          it 'should return invoice model' do
            allow(@stripe_event).to receive(:get_account_and_invoice).and_return [nil, @invoice]
            allow(Invoice).to receive(:find_by).with(stripe_invoice_id: @invoice['id'])\
                                               .and_return @invoice
            expect(@stripe_event.related(@desired_model)).to eq @invoice
          end
        end
      end
    end

    describe 'self.process!()' do
      context 'with event and payload' do
        before do
          @stripe_event = mock_model(StripeEvent)
          @event_id = 'evt_1K3eKD2LsKuf8PTnlLJ7FoI8'
          @event_type = 'invoice.finalized'
          @data = OpenStruct.new(object: 'foo')

          @event = OpenStruct.new(
            id: @event_id,
            type: @event_type,
            data: @data
          )

          @payload = 'foo'
        end

        it 'should create a StripeEvent' do
          expect(StripeEvent).to receive(:create).with(
            event_id: @event_id,
            event_type: @event_type,
            status: 'received',
            body: @payload
          ).and_return @stripe_event
          allow(@stripe_event).to receive(:go!)

          StripeEvent.process!(@event, @payload)
        end

        it 'should handle event' do
          allow(StripeEvent).to receive(:create).and_return(@stripe_event)
          expect(@stripe_event).to receive(:go!)
          StripeEvent.process!(@event, @payload)
        end
      end
    end
  end

  describe 'Handlers' do
    describe 'handle_invoice_finalized!' do
      context 'with event' do
        before :each do
          @stripe_event = build(:stripe_event, :invoice_finalized)
          @invoice = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with incorrect event type' do
          before :each do
            @stripe_event.event_type = 'foo'
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_finalized! }.to raise_error StandardError
          end
        end

        context 'with valid customer' do
          before :each do
            @account = build(:account)
            allow(Account).to receive(:find_by).and_return(@account)
          end

          it 'should create invoice for customer' do
            expect(StripeInvoice).to receive(:create_for_account).with(@account, @invoice)
            @stripe_event.handle_invoice_finalized!
          end

          context 'with link_to_invoice_id in metadata' do
            before :each do
              body = JSON.parse(@stripe_event.body)
              body['data']['object']['metadata'] = {
                link_to_invoice_id: 123
              }
              @stripe_event.body = body.to_json
              @invoice = JSON.parse(@stripe_event.body)['data']['object']
            end

            it 'should link Stripe invoice to existing ARP invoice' do
              expect(StripeInvoice).to receive(:link_to_invoice).with(123, @invoice)
              @stripe_event.handle_invoice_finalized!
            end
          end
        end

        context 'without valid customer' do
          before :each do
            # No such account given this Stripe customer_id
            allow(Account).to receive(:find_by).and_return(nil)
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_finalized! }.to raise_error StandardError
          end
        end
      end
    end

    describe 'handle_invoice_paid!' do
      context 'with event' do
        before :each do
          @stripe_event = build(:stripe_event, :invoice_paid)
          @invoice = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with incorrect event type' do
          before :each do
            @stripe_event.event_type = 'foo'
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_finalized! }.to raise_error StandardError
          end
        end

        context 'with valid customer' do
          before :each do
            @account = build(:account)
            allow(Account).to receive(:find_by).and_return(@account)
          end

          it 'should create payment' do
            expect(StripeInvoice).to receive(:create_payment).with(@account, @invoice)
            @stripe_event.handle_invoice_paid!
          end

          it 'should send a sales receipt email' do
            @stripe_invoice = double(StripeInvoice)
            allow(StripeInvoice).to receive(:create_payment).with(@account, @invoice) { @stripe_invoice }
            mailer = double(:mailer)
            expect(mailer).to receive(:deliver_later)
            expect(Mailers::Stripe).to receive(:sales_receipt)\
              .with(@stripe_invoice, hosted_invoice_url: @invoice['hosted_invoice_url'])\
              .and_return mailer
            @stripe_event.handle_invoice_paid!
          end
        end

        context 'without valid customer' do
          before :each do
            # No such account given this Stripe customer_id
            allow(Account).to receive(:find_by).and_return(nil)
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_paid! }.to raise_error StandardError
          end
        end
      end
    end

    describe 'handle_invoice_payment_failed!' do
      context 'with event' do
        before :each do
          @stripe_event = build(:stripe_event, :invoice_payment_failed)
          @invoice = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with incorrect event type' do
          before :each do
            @stripe_event.event_type = 'foo'
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_payment_failed! }.to raise_error StandardError
          end
        end

        context 'with valid customer' do
          before :each do
            @account = build(:account)
            allow(Account).to receive(:find_by).and_return(@account)
          end

          it 'should send a decline notice email' do
            mailer = double(:mailer)
            expect(mailer).to receive(:deliver_later)
            expect(Mailers::Stripe).to receive(:payment_failed)\
              .with(@account, hosted_invoice_url: @invoice['hosted_invoice_url'])\
              .and_return mailer
            @stripe_event.handle_invoice_payment_failed!
          end
        end

        context 'without valid customer' do
          before :each do
            # No such account given this Stripe customer_id
            allow(Account).to receive(:find_by).and_return(nil)
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_payment_failed! }.to raise_error StandardError
          end
        end
      end
    end

    describe 'handle_payment_method_attached!' do
      context 'with event and account' do
        before :each do
          @account = build(:account)
          @stripe_event = build(:stripe_event, :payment_method_attached)
          @payment_method = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with incorrect event type' do
          before :each do
            @stripe_event.event_type = 'foo'
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_finalized! }.to raise_error StandardError
          end
        end

        it 'should update customer default payment method in Stripe and locally' do
          customer_id = @payment_method['customer']
          expect(Stripe::Customer).to receive(:update).with(customer_id, {
                                                              invoice_settings: {
                                                                default_payment_method: @payment_method['id']
                                                              }
                                                            })
          expect(Account).to receive(:find_by).with(stripe_customer_id: customer_id)\
                                              .and_return @account
          expect(@account).to receive(:stripe_payment_method_id=).with(@payment_method['id'])
          expect(@account).to receive(:save)

          allow(@account).to receive(:offload_billing?)

          @stripe_event.handle_payment_method_attached!
        end
      end
    end

    describe 'handle_charge_refunded!' do
      context 'with event and account' do
        before :each do
          @account = build(:account)
          @stripe_event = build(:stripe_event, :charge_refunded)
          allow(@stripe_event).to receive(:body) {
            StripeFixtures.event_charge_refunded.to_json
          }
          @charge = JSON.parse(@stripe_event.body)['data']['object']
        end

        context 'with incorrect event type' do
          before :each do
            @stripe_event.event_type = 'foo'
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_finalized! }.to raise_error StandardError
          end
        end

        context 'with valid customer' do
          before :each do
            @account = build(:account)
            allow(Account).to receive(:find_by).and_return(@account)
          end

          it 'should process refund' do
            expect(StripeInvoice).to receive(:process_refund).with(@charge)
            @stripe_event.handle_charge_refunded!
          end

          it 'should send a refund receipt email' do
            allow(StripeInvoice).to receive(:process_refund).with(@charge) { 10 }
            mailer = double(:mailer)
            expect(mailer).to receive(:deliver_later)
            expect(Mailers::Stripe).to receive(:refund)\
              .with(@account, 10, receipt_url: @charge['receipt_url'])\
              .and_return mailer
            @stripe_event.handle_charge_refunded!
          end
        end

        context 'without valid customer' do
          before :each do
            # No such account given this Stripe customer_id
            allow(Account).to receive(:find_by).and_return(nil)
          end

          it 'should raise error' do
            expect { @stripe_event.handle_invoice_paid! }.to raise_error StandardError
          end
        end
      end
    end
  end
end
