require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../my_spec_helper')

describe '/invoices/pay.erb' do
  before do
    @account = stub_model(Account)
    assigns[:account] = @account
  end

  context 'account does not have unpaid invoices' do
    before do
      assigns[:outstanding_balance] = 0
    end

    it 'should display thank you greeting' do
      render '/invoices/pay.erb'
      response.should have_tag("div[class=notice-green]", /All invoices are paid.*Thank you/)
    end
  end

  context 'account has unpaid invoices' do
    before do
      @outstanding_balance = 444
      assigns[:outstanding_balance] = @outstanding_balance
    end

    context 'account does not have a credit card' do
      before do
        assigns[:credit_card] = nil
      end

      it 'should display button to add credit card' do
        render '/invoices/pay.erb'
        response.should have_tag("div[class=notice-green]", /Your account does not have a credit card/)
        response.should have_tag("a[href=?]", new_account_credit_card_path(@account.id), /Add Credit Card/)
      end
    end

    context 'account has a credit card' do
      before do
        @cc_num = '4111111111111111'

        assigns[:credit_card] = stub_model(CreditCard,
                                           :number => @cc_num,
                                           :display_number => '1111')
      end

      it 'should display link to change credit card' do
        render '/invoices/pay.erb'
        response.should have_tag("a[href=?]", new_account_credit_card_path(@account.id), /submit a new one/)
      end

      context 'cc_e cookie matches credit card' do
        before do
          assigns[:credit_card_number] = @cc_num
        end

        it 'should have hidden input for credit card number' do
          render '/invoices/pay.erb'
          response.should have_tag("input[type=hidden][name=credit_card_number][value=?]", @cc_num)
        end
      end

      context 'cc_e cookie does not match credit card' do
        before do
          assigns[:credit_card_number] = nil
        end

        it 'should display input for credit card number' do
          render '/invoices/pay.erb'
          response.should have_tag("input[type=text][name=credit_card_number]")
        end
      end

      it 'should display current card to use' do
        render '/invoices/pay.erb'
        response.should have_tag("div[id=credit-card]", /Credit Card.*\*\*1111/m)
      end

      it 'should display confirmation button' do
        render '/invoices/pay.erb'
        response.should have_tag("button[type=submit]", /Authorize/)
      end

      it 'should have hidden input for amount to pay' do
        render '/invoices/pay.erb'
        response.should have_tag("input[type=hidden][name=confirmed_amount][value=?]", @outstanding_balance)
      end
    end
  end
end
