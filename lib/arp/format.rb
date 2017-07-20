module Format
  def money(amount, currency='USD')
    case currency
    when 'USD'
      if amount == 0
        return 'Free'
      end

      if amount
        "#{seperate_number(sprintf('$%01.2f', amount))}"
      else
        'Free'
      end
    when 'GBP'
      amount ? "&pound;#{seperate_number(sprintf('%01.2f', amount))}" : '&pound;0.00'
    when 'EUR'
      amount ? "&euro;#{seperate_number(sprintf('%01.2f', amount))}" : '&euro;0.00'
    when 'CAD'
      amount ? "$#{seperate_number(sprintf('%01.2f', amount))} CAD" : '$0.00 CAD'
    when "JPY"
      amount ? "&yen;#{seperate_number(sprintf('%01.2f', amount))}" : '&yen;0.00'
    else
      if amount
        "#{seperate_number(sprintf('%01.2f', amount))} #{currency}"
      else
        '0.00 ' + currency
      end
    end
  end

  def money2(amount)
    "$" + seperate_number(money_without_currency_formatting(amount)).to_s
  end
  
  def seperate_number(number)
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join('.')
  end

  def money_without_currency_formatting(amount)
    amount ? sprintf("%01.2f", amount) : '0.00'
  end

  def us_date(d)
    if d
      d.strftime("%m-%d-%Y")
    end
  end

  def date_in_words(d)
    if d
      d.strftime("%b %d, %Y")
    end
  end
end

if defined?(describe) 
  include Format

  describe Format do
    describe "money()" do
      it "should return 'Free' for amount of 0.00" do
        money(0.00).should == 'Free'
      end
      it "should return 'Free' for amount of nil" do
        money(nil).should == 'Free'
      end
    end
  end
end
