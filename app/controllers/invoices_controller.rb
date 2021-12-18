class InvoicesController < ProtectedController
  before_action :payment_system_maintenance, :only => [:pay, :pay_confirm]

  def index
    @invoices = @account.invoices.active.paginate(:page => params[:page],
                                                  :per_page => (params[:per_page] ||= 10).to_i).order('date desc')
    @unpaid_invoices = @account.invoices_unpaid
  end

  def show
    @invoice = @account.invoices.active.find(params[:id])
  end

  def pay
    redirect_to dashboard_path and return if @account.offload_billing?

    @invoices = @account.invoices_unpaid.order('date desc')
    @outstanding_balance = @account.invoices_outstanding_balance
    @credit_card = @account.credit_card

    if @credit_card
      cc_e  = cookies['cc_e']
      cc_iv = cookies['cc_iv']

      cc_e = Base64.decode64(cc_e) if cc_e

      @credit_card_number = nil

      if cc_e && cc_iv
        begin
          @credit_card_number = SimpleCrypt.decrypt(cc_e, cc_iv).to_s

          # Only if the cookie matches current card, do we use it
          unless @credit_card_number =~ /#{@credit_card.display_number}$/
            @credit_card_number = nil
          end
        rescue OpenSSL::Cipher::CipherError => e
          Mailer.simple_notification("Credit Card Error", e.message + "\n" + "Account ID: #{@account.id} (#{@account.display_account_name})").deliver_now
          cookies.delete(:cc_e)
          cookies.delete(:cc_iv)
        end
      end
    end
  end

  def pay_confirm
    redirect_to dashboard_path and return if @account.offload_billing?

    @credit_card_number  = params[:credit_card_number].to_s
    @confirmed_amount    = params[:confirmed_amount].to_f

    # Grab outstanding balance and unpaid invoices atomically
    ActiveRecord::Base.transaction do
      @outstanding_balance = @account.invoices_outstanding_balance.to_f
      @unpaid_invoices = @account.invoices_unpaid
    end

    # No credit card?  Go back
    if @credit_card_number.empty?
      flash[:error] = "Please confirm your credit card number"
      redirect_to pay_account_invoices_path(@account.id) and return
    end

    # Confirmed amount not what we see outstanding?  Go back
    if @confirmed_amount != @outstanding_balance
      flash[:error] = "There was an error processing this request and support has been notified.  Please try again later."
      simple_email("PAY: @confirmed_amount != @outstanding_balance", "#{@confirmed_amount} != #{@outstanding_balance} for Account ID #{@account.id}") rescue nil

      redirect_to pay_account_invoices_path(@account.id) and return
    end

    # No more unpaid invoices?  What are you doing here then?!  Go back
    if @unpaid_invoices.empty?
      redirect_to pay_account_invoices_path(@account.id) and return
    end

    # Build credit card
    cc = @account.credit_card
    cc.number = @credit_card_number

    line_items = @account.sales_receipt_line_items(@unpaid_invoices)

    simple_email("PAY: (BEGIN) #{@account.display_account_name} (#{@account.id}) charge " + money_without_currency_formatting(@confirmed_amount) + "", "") rescue nil

    charge_rec, sr = cc.charge_with_sales_receipt(@confirmed_amount,
                                                  line_items,
                                                  :email_decline_notice => false,
                                                  :email_sales_receipt  => true)

    unless sr
      # Meh
      # We need to change this to charge_rec.gateway_response if/when
      # charge_with_sales_receipt() returns the charge even on failure
      gw_response = YAML.load(cc.charges.last.gateway_response).message rescue nil

      flash[:error] = "There was a problem charging your credit card.  Please try a different card or try again later."

      flash[:error] += "<br><br>Gateway response: #{gw_response}" if gw_response && !gw_response.empty?

      simple_email("PAY: (END) #{@account.display_account_name} (#{@account.id}) charge " + money_without_currency_formatting(@confirmed_amount) + " (DECLINED)", "") rescue nil

      redirect_to pay_account_invoices_path(@account.id) and return
    end

    simple_email("PAY: (END) #{@account.display_account_name} (#{@account.id}) charge " + money_without_currency_formatting(@confirmed_amount) + " (SUCCESS!)", "") rescue nil

    @now = Time.now

    # Don't ask me why we have to re-find it.  Using charge_rec directly will
    # cause: "instance of IO needed" to be thrown from YAML::load below
    charge_rec = Charge.find(charge_rec.id)

    @transaction_id = YAML::load(charge_rec.gateway_response).params["transaction_id"]

    @unpaid_invoices.each do |invoice|
      invoice.paid = true
      invoice.save

      invoice.payments.create({
        :account_id => @account.id,
        :date => @now,
        :reference_number => @transaction_id,
        :method => 'Credit Card',
        :amount => invoice.total
      })

      simple_email("PAY: #{@account.display_account_name} (#{@account.id}) Invoice #{invoice.id} marked PAID (#{@transaction_id}): " + money_without_currency_formatting(invoice.total.to_f) + "", "") rescue nil
    end
  end

  private

  def payment_system_maintenance
    if File.exists?($PAYMENT_SYSTEM_DISABLED_LOCKFILE)
      flash[:error] = "Our payment system is temporarily unavailable due to scheduled maintenance.  Please try again later."

      redirect_to account_invoices_path(@account.id) and return
    end
  end
end
