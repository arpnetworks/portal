class CreditCardsController < ProtectedController
  def new
    @credit_card = CreditCard.new

    @credit_card.first_name = @account.first_name.to_s + " " +
                              @account.last_name.to_s
    @credit_card.billing_address_1 = @account.address1
    @credit_card.billing_address_2 = @account.address2
    @credit_card.billing_city = @account.city
    @credit_card.billing_state = @account.state
    @credit_card.billing_postal_code = @account.zip

    country = @account.country
    if country && country.length == 2
      @credit_card.billing_country_iso_3166 = country
    end
  end

  def create
    if params[:credit_card]
      # Must coerce some values of the form to fit CreditCard model
      first_name, *last_name = params[:credit_card][:first_name].split(' ')
      last_name = last_name.join(' ')

      if last_name.empty?
        last_name = first_name
      end

      params[:credit_card][:first_name] = first_name
      params[:credit_card][:last_name] = last_name

      params[:credit_card][:billing_name] = first_name.to_s + ' ' + last_name.to_s

      # Strip dashes and spaces
      params[:credit_card][:number].gsub!(/[ \-]/, '')

      cc_num = params[:credit_card][:number]
      display_number = cc_num[cc_num.size-4..-1]
      params[:credit_card][:display_number] = display_number
    end

    @credit_card = CreditCard.new(credit_card_params)
    @credit_card.account_id = @account.id

    if @credit_card.valid?
      iv = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
      cookies[:cc_iv] = {
        :value => iv,
        :expires => 10.years.from_now
      }
      cookies[:cc_e] = {
        :value => SimpleCrypt.encrypt(@credit_card.number, iv),
        :expires => 10.years.from_now
      }
    end

    if @credit_card.save
      flash[:notice] = "Thank you for updating your billing information"
      redirect_to(dashboard_path)

      body = ""
      status = @account.suspended? ? "[SUSPENDED]" : ""

      simple_email("CC: #{@account.display_account_name} (#{@account.id}) #{status} updated their credit card: **#{display_number}", body) rescue nil

      return
    end

    render :new
  end

  private

  def credit_card_params
    params.require(:credit_card).permit(
      :number,
      :month,
      :year,
      :first_name,
      :last_name,
      :billing_name,
      :billing_company,
      :billing_address_1,
      :billing_address_2,
      :billing_city,
      :billing_state,
      :billing_postal_code,
      :billing_country_iso_3166,
      :billing_phone
    )
  end
end
