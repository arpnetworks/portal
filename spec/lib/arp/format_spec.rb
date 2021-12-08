require 'rails_helper'
require 'arp_spec_helper'

RSpec.describe Format do

  module TestARPFormat
    include Format
  end

  describe "money()" do
    it "should return 'Free' for amount of 0.00" do
      expect(TestARPFormat.money(0.00)).to eq('Free')
    end
    it "should return 'Free' for amount of nil" do
      expect(TestARPFormat.money(nil)).to eq('Free')
    end
  end

end