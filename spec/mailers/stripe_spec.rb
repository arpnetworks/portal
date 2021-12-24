require 'rails_helper'

RSpec.describe Mailers::Stripe, type: :mailer do
  context 'with account' do
    before do
      @account = build(:account)
    end

    context 'with payment_failed mailer' do
      before do
        @mailer = Mailers::Stripe.payment_failed(@account)
      end

      describe 'payment_failed' do
        it 'should render the subject' do
          expect(@mailer.subject).to eq '[Action Required] Payment Method Declined'
        end

        it 'should render the sender email' do
          expect(@mailer.from).to eql(['billing@arpnetworks.com'])
        end

        it 'should render the receiver email' do
          expect(@mailer.to).to eql([@account.email_for_sales_receipts])
        end

        it 'should render nice greeting' do
          expect(@mailer.body.encoded).to match("Hi #{@account.display_name}")
        end

        context 'if hosted invoice URL provided' do
          before :each do
            @opts = {
              hosted_invoice_url: 'https://invoice.stripe.com/i/something-something-something'
            }
            @mailer = Mailers::Stripe.payment_failed(@account, @opts)
          end

          it 'should render Stripe invoice link' do
            expect(@mailer.body.encoded).to match('https://invoice.stripe.com/')
          end
        end

        context 'if hosted invoice URL not provided' do
          before :each do
            @mailer = Mailers::Stripe.payment_failed(@account)
          end

          it 'should render info about Portal login' do
            expect(@mailer.body.encoded).to match('portal.arpnetworks.com')
            expect(@mailer.body.encoded).to match(@account.login)
          end
        end
      end
    end

    context 'with sales_receipt mailer' do
      before do
        @mailer = Mailers::Stripe.sales_receipt(@account)
      end

      describe 'sales_receipt' do
        it 'should render the subject' do
          expect(@mailer.subject).to match 'Sales Receipt'
        end

        it 'should render the sender email' do
          expect(@mailer.from).to eql(['billing@arpnetworks.com'])
        end

        it 'should render the receiver email' do
          expect(@mailer.to).to eql([@account.email_for_sales_receipts])
        end

        it 'should render nice greeting' do
          expect(@mailer.body.encoded).to match("Hi #{@account.display_name}")
        end

        context 'if hosted invoice URL provided' do
          before :each do
            @opts = {
              hosted_invoice_url: 'https://invoice.stripe.com/i/something-something-something'
            }
            @mailer = Mailers::Stripe.sales_receipt(@account, @opts)
          end

          it 'should render Stripe invoice link' do
            expect(@mailer.body.encoded).to match('https://invoice.stripe.com/')
          end
        end
      end
    end
  end
end
