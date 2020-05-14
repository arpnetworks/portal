require File.dirname(__FILE__) + '/../../rails_helper'

describe '/invoices/pay.erb' do
  include RSpecHtmlMatchers

  before do
    @account = stub_model(Account)
    assign(:account, @account)
  end

  context 'account does not have unpaid invoices' do
    before do
      assign(:outstanding_balance, 0)
    end

    it 'should display thank you greeting' do
      render template: '/invoices/pay.erb'
      expect(response).to have_tag("div[class=notice-green]", text: /All invoices are paid.*Thank you/)
    end
  end

  context 'account has unpaid invoices' do
    before do
      @outstanding_balance = 444
      assign(:outstanding_balance, @outstanding_balance)
    end

    context 'account does not have a credit card' do
      before do
        assign(:credit_card, nil)
      end

      it 'should display button to add credit card' do
        render template: '/invoices/pay.erb'
        expect(response).to have_tag("div[class=notice-green]", text: /Your account does not have a credit card/)
        expect(response).to have_tag("a[href='%s']" % new_account_credit_card_path(@account.id), text: /Add Credit Card/)
      end
    end

    context 'account has a credit card' do
      before do
        @cc_num = '4111111111111111'

        assign(:credit_card, stub_model(CreditCard,
                                        number: @cc_num,
                                        display_number: '1111'))
      end

      it 'should display link to change credit card' do
        render template: '/invoices/pay.erb'
        expect(response).to have_tag("a[href='%s']" % new_account_credit_card_path(@account.id), text: /submit a new one/)
      end

      context 'cc_e cookie matches credit card' do
        before do
          assign(:credit_card_number, @cc_num)
        end

        it 'should have hidden input for credit card number' do
          render template: '/invoices/pay.erb'
          expect(response).to have_tag("input[type=hidden][name=credit_card_number][value='%s']" % @cc_num)
        end
      end

      context 'cc_e cookie does not match credit card' do
        before do
          assign(:credit_card_number, nil)
        end

        it 'should display input for credit card number' do
          render template: '/invoices/pay.erb'
          expect(response).to have_tag("input[type=text][name=credit_card_number]")
        end
      end

      it 'should display current card to use' do
        render template: '/invoices/pay.erb'
        expect(response).to have_tag("div[id=credit-card]", text: /Credit Card.*\*\*1111/m)
      end

      it 'should display confirmation button' do
        render template: '/invoices/pay.erb'
        expect(response).to have_tag("button[type=submit]", text: /Authorize/)
      end

      it 'should have hidden input for amount to pay' do
        render template: '/invoices/pay.erb'
        expect(response).to have_tag("input[type=hidden][name=confirmed_amount][value='%s']" % @outstanding_balance)
      end
    end
  end
end
