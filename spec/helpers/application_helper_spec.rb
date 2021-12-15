require 'rails_helper'

describe ApplicationHelper do
  include ApplicationHelper

  describe 'billing_interval_in_words()' do
    it "should return 'Never' for 0" do
      expect(billing_interval_in_words(0)).to eq 'Never'
    end

    it "should return 'Never' for nil" do
      expect(billing_interval_in_words(nil)).to eq 'Never'
    end

    it "should return 'Monthly' for 1" do
      expect(billing_interval_in_words(1)).to eq 'Monthly'
    end

    it "should return 'Quarterly' for 3" do
      expect(billing_interval_in_words(3)).to eq 'Quarterly'
    end

    it "should return 'Every X months' for 1 < X < 12 (except for 3)" do
      (2..11).to_a.each do |n|
        next if n == 3

        expect(billing_interval_in_words(n)).to eq "Every #{n} months"
      end
    end

    it "should return 'Annual' for 12'" do
      expect(billing_interval_in_words(12)).to eq 'Annual'
    end

    it "should return 'every XX months' for X > 12" do
      expect(billing_interval_in_words(13)).to eq 'Every 13 months'
    end
  end

  describe 'service_total_in_words()' do
    before do
      @service_totals = { 1 => 300, 5 => 100, 3 => 200, 12 => 700 }
    end

    it "should contain 'Monthly Recurring Charges' total" do
      expect(service_total_in_words(100, 1)).to eq 'Monthly Recurring Charges: $100'
    end

    it "should contain 'Annual Recurring Charges' total" do
      expect(service_total_in_words(200, 12)).to eq 'Annual Recurring Charges: $200'
    end

    it "should contain 'Quarterly Recurring Charges' total" do
      expect(service_total_in_words(300, 3)).to eq 'Quarterly Recurring Charges: $300'
    end

    it "should contain 'Every X Months Recurring Charges' total" do
      expect(service_total_in_words(400, 5)).to eq 'Every 5 months Recurring Charges: $400'
    end

    it "should contain 'No charges' if total is zero" do
      expect(service_total_in_words(0, 1)).to eq 'No charges'
    end

    it "should contain 'Non-recurring Charges' total if interval is 0" do
      expect(service_total_in_words(250, 0)).to eq 'Non-recurring Charges: $250'
    end
  end

  describe 'one_line_address_for_account()' do
    before do
      @addr1   = '2550 N. Hollywood Way'
      @addr2   = 'Suite #105'
      @city    = 'Burbank'
      @state   = 'CA'
      @zip     = '91505'
      @country = 'USA'
    end

    def do_account
      @account = Account.new(address1: @addr1,
                             address2: @addr2,
                             city: @city,
                             state: @state,
                             zip: @zip,
                             country: @country)
    end

    it 'should look like this when only address1 is provided' do
      @addr2 = @city = @state = @zip = @country = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @addr1
    end

    it 'should look like this when only address2 is provided' do
      @addr1 = @city = @state = @zip = @country = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @addr2
    end

    it 'should look like this when only city is provided' do
      @addr1 = @addr2 = @state = @zip = @country = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @city
    end

    it 'should look like this when only state is provided' do
      @addr1 = @addr2 = @city = @zip = @country = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @state
    end

    it 'should look like this when only zip is provided' do
      @addr1 = @addr2 = @city = @state = @country = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @zip
    end

    it 'should look like this when only country is provided' do
      @addr1 = @addr2 = @city = @state = @zip = ''
      do_account
      expect(one_line_address_for_account(@account)).to eq @country
    end

    it 'should look like this when all information is provided' do
      do_account
      expect(one_line_address_for_account(@account)).to eq \
        "#{@city}, #{@state}, #{@zip}, #{@country}"
    end
  end
end
