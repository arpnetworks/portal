require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

context InvoicesController do
  before(:context) do
    create_user!
  end

  before do
    @account = login_as_user!

    # Let controller use this instance of @account object, not the one it
    # finds after logging in (so we can mock / stub a lot easier)
    allow(Account).to receive(:find).with(@account.id) { @account }
  end

  specify 'should be a InvoicesController' do
    expect(controller).to be_an_instance_of(InvoicesController)
  end

  context 'index action' do
    specify 'should respond with success' do
      get :index, params: { account_id: @account.id }
      expect(@response).to be_success
    end
  end

  context 'pay action' do
    before do
      @cc_num = '4111111111111111'
      @credit_card = build :credit_card, number: @cc_num
      allow(@account).to receive(:credit_card) { @credit_card }
    end

    def do_get(opts = {})
      get :pay, params: { account_id: @account.id }.merge(opts)
    end

    specify 'should respond with success' do
      do_get
      expect(@response).to be_success
    end

    context 'when payment system is disabled' do
      before do
        allow(File).to receive(:exists?) { true }
      end

      specify 'should return to invoices index with notice' do
        do_get
        expect(flash[:error]).to_not be_nil
        expect(@response).to redirect_to(account_invoices_path(@account.id))
      end
    end

    context 'with cc_e and cc_ie cookies' do
      before do
        @cc_iv = 'hzghaqxusktkvghydsjavcialquzxvbexxjqbcrdtwlrqncnnt'
        @cc_e = SimpleCrypt.encrypt(@cc_num, @cc_iv)

        @request.cookies['cc_e']  = @cc_e
        @request.cookies['cc_iv'] = @cc_iv
      end

      specify 'should decrypt CC' do
        expect(SimpleCrypt).to receive(:decrypt).with(@cc_e, @cc_iv)
        do_get
      end

      context 'when decrypted CC matches account CC' do
        before do
          allow(SimpleCrypt).to receive(:decrypt) { @cc_num }
        end

        specify 'should use decrypted CC' do
          do_get
          expect(assigns(:credit_card_number)).to eq @cc_num
        end
      end

      context 'when decrypted CC does not match account CC' do
        before do
          @cc_num = '4242424242424242'
          allow(SimpleCrypt).to receive(:decrypt) { @cc_num }
        end

        specify 'should not use decrypted CC (assign nil)' do
          do_get
          expect(assigns(:credit_card_number)).to eq nil
        end
      end
    end
  end

  context 'pay_confirm action' do
    def do_post(opts = {})
      post :pay_confirm, params: { account_id: @account.id,
                                   credit_card_number: @cc_num,
                                   confirmed_amount: @confirmed_amount }.merge(opts)
    end

    context 'when payment system is disabled' do
      before do
        allow(File).to receive(:exists?) { true }
      end

      specify 'should return to invoices index with notice' do
        do_post
        expect(flash[:error]).to_not be_nil
        expect(@response).to redirect_to(account_invoices_path(@account.id))
      end
    end

    context 'with credit card number' do
      before do
        @cc_num = '4111111111111111'
      end

      context 'with unpaid invoices' do
        before do
          @inv1 = double(:invoice_1,
                         id: 500,
                         date: '01-01-1970',
                         line_items: [])
          @inv2 = double(:invoice_2,
                         id: 501,
                         date: '01-01-1970',
                         line_items: [])
          @unpaid_invoices = [@inv1, @inv2]
          allow(@account).to receive(:invoices_unpaid).and_return(@unpaid_invoices)
        end

        context 'when confirmed payment amount matches outstanding balance' do
          before do
            @confirmed_amount = 444.00
            allow(@account).to receive(:invoices_outstanding_balance).and_return(@confirmed_amount)
            allow(@account).to receive(:sales_receipt_line_items).with(@unpaid_invoices) { [] }
          end

          specify 'should build credit card' do
            @cc = double(:credit_card,
                         charge_with_sales_receipt: nil,
                         charges: [])
            expect(@account).to receive(:credit_card).and_return(@cc)
            expect(@cc).to receive(:number=).with(@cc_num)
            do_post
          end

          context 'with built credit card' do
            before do
              @cc = double(:credit_card,
                           :number= => @cc_num,
                           :charge_with_sales_receipt => nil,
                           :charges => [])
              allow(@account).to receive(:credit_card).and_return(@cc)
            end

            specify 'should build line items for receipt' do
              expect(@account).to receive(:sales_receipt_line_items).with(@unpaid_invoices)
              do_post
            end

            specify 'should charge outstanding balance' do
              @li = double(:line_items)
              allow(@account).to receive(:sales_receipt_line_items).and_return(@li)
              expect(@cc).to receive(:charge_with_sales_receipt).with(\
                @confirmed_amount, @li,
                email_decline_notice: false,
                email_sales_receipt: true
              )
              do_post
            end

            context 'when charge successful' do
              before do
                @sr = double(:sales_receipt)
                @cr = double(:charge_record, id: 500)

                @transaction_id = '0JU013998M1143205'

                allow(@cr).to receive(:gateway_response).and_return("--- !ruby/object:ActiveMerchant::Billing::Response \nauthorization: 0JU013998M1143205\navs_result: \n code: X\n postal_match: Y\n street_match: Y\n message: Street address and 9-digit postal code match.\ncvv_result: \n code: M\n message: Match\nfraud_review: false\nmessage: Success\nparams: \n timestamp: \"2013-11-27T10:02:25Z\"\n correlation_id: ce7da3479e6f2\n transaction_id: #{@transaction_id}\n amount: \"444.00\"\n amount_currency_id: USD\n build: \"8620107\"\n version: \"52.0\"\n avs_code: X\n ack: Success\n cvv2_code: M\nsuccess: true\ntest: true\n")

                allow(@cc).to receive(:charge_with_sales_receipt).and_return([@cr, @sr])
                allow(Charge).to receive(:find).and_return(@cr)
              end

              specify 'should mark invoices paid' do
                [@inv1, @inv2].each do |invoice|
                  expect(invoice).to receive(:paid=).with(true)
                  expect(invoice).to receive(:save).and_return(true)
                  allow(invoice).to receive(:total).and_return(222)
                end

                @now = Time.now
                allow(Time).to receive(:now).and_return(@now)

                # Payment Record #1
                @payments_1 = double(:payments_1)
                expect(@payments_1).to receive(:create).with({
                                                               account_id: @account.id,
                                                               date: @now,
                                                               reference_number: @transaction_id,
                                                               method: 'Credit Card',
                                                               amount: @inv1.total
                                                             })
                expect(@inv1).to receive(:payments).and_return(@payments_1)

                # Payment Record #2
                @payments_2 = double(:payments_2)
                expect(@payments_2).to receive(:create).with({
                                                               account_id: @account.id,
                                                               date: @now,
                                                               reference_number: @transaction_id,
                                                               method: 'Credit Card',
                                                               amount: @inv2.total
                                                             })
                expect(@inv2).to receive(:payments).and_return(@payments_2)

                do_post
              end

              specify 'should render success page' do
                # Stub it all out
                [@inv1, @inv2].each do |inv|
                  allow(inv).to receive(:paid=)
                  allow(inv).to receive(:save)
                  allow(inv).to receive(:total)
                  allow(inv).to receive(:payments).and_return(double(:payments, create: nil))
                end

                do_post
                expect(@response).to render_template('pay_confirm')
              end
            end

            context 'when charge unsuccessful' do
              before do
                allow(@cc).to receive(:charge_with_sales_receipt).and_return(nil)
              end

              specify 'should redirect to pay action with decline notice' do
                do_post
                expect(flash[:error]).to_not be_nil
                expect(@response).to redirect_to(pay_account_invoices_path(@account.id))
              end
            end
          end
        end

        context 'when confirmed payment amount does not match outstanding balance' do
          before do
            @confirmed_amount = 444.00
            allow(@account).to receive(:invoices_outstanding_balance).and_return(777.00)
          end

          specify 'should return to pay action with notice' do
            do_post
            expect(flash[:error]).to_not be_nil
            expect(@response).to redirect_to(pay_account_invoices_path(@account.id))
          end
        end
      end

      context 'without unpaid invoices' do
        before do
          allow(@account).to receive(:invoices_unpaid).and_return([])
        end

        specify 'should return to pay action' do
          do_post
          expect(@response).to redirect_to(pay_account_invoices_path(@account.id))
        end
      end
    end

    context 'without credit card number' do
      before do
        @cc_num = ''
      end

      specify 'should return to pay action with notice' do
        do_post
        expect(flash[:error]).to_not be_nil
        expect(@response).to redirect_to(pay_account_invoices_path(@account.id))
      end
    end
  end
end
