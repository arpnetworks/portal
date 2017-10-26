require File.dirname(__FILE__) + '/../rails_helper'

context "Vlan class with fixtures loaded" do
  before(:all) do
    @code = 'lax'
    @lax = create :location, code: @code
    create :ip_block, vlan: 102, location: @lax
    create :ip_block, vlan: 104, location: @lax
    create :ip_block, vlan: 105, location: @lax
    create :ip_block, vlan: 106, location: @lax, available: true
    create :ip_block, vlan: 107, location: @lax, available: true
    create :ip_block, vlan: 108, location: @lax, available: true
    create :vlan, vlan: 1, label: 'Native VLAN',  location: @lax
    create :vlan, vlan: 100, label: 'FidoNet',  location: @lax
    create :vlan, vlan: 101, label: 'VLAN 101', location: @lax
    create :vlan, vlan: 440, label: 'VLAN 440', location: @lax
  end

  context "next_available()" do
    specify "should return next available VLAN" do
      Vlan.next_available.should == [103]
    end

    specify "should not return a VLAN already in the VLAN database" do
      Vlan.next_available.should_not == [101]
    end

    specify "should respect limit" do
      Vlan.next_available(:limit => 3).should == [103, 109, 110]
    end

    specify "should respect start_at" do
      Vlan.next_available(:start_at => 400).should == [400]
      Vlan.next_available(:start_at => 440).should == [441]
    end
  end

  context "in_use()" do
    before do
      @in_use = Vlan.in_use(@lax.id)
    end

    specify "should include all VLANs assigned in IpBlock's" do
      (@in_use & [102, 104, 105]).should == [102, 104, 105]
    end

    specify "should include all VLANs assigned in VLAN database" do
      (@in_use & [1, 101, 440]).should == [1, 101, 440]
    end

    specify "should be sorted and not return duplicates" do
      @in_use.should == [1, 100, 101, 102, 104, 105, 106, 107, 108, 440]
    end
  end
end
