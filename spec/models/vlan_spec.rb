require 'rails_helper'

context 'Vlan class with fixtures loaded' do
  before do
    @code = 'lax'
    @lax = Location.find_by(code: @code) || create(:location, code: @code)

    create :ip_block, vlan: 102, location: @lax unless IpBlock.find_by(vlan: 102)
    create :ip_block, vlan: 104, location: @lax unless IpBlock.find_by(vlan: 104)
    create :ip_block, vlan: 105, location: @lax unless IpBlock.find_by(vlan: 105)
    create :ip_block, vlan: 106, location: @lax, available: true unless IpBlock.find_by(vlan: 106)
    create :ip_block, vlan: 107, location: @lax, available: true unless IpBlock.find_by(vlan: 107)
    create :ip_block, vlan: 108, location: @lax, available: true unless IpBlock.find_by(vlan: 108)
    create :vlan, vlan: 1, label: 'Native VLAN', location: @lax unless Vlan.find_by(vlan: 1)
    create :vlan, vlan: 100, label: 'FidoNet',  location: @lax   unless Vlan.find_by(vlan: 100)
    create :vlan, vlan: 101, label: 'VLAN 101', location: @lax   unless Vlan.find_by(vlan: 101)
    create :vlan, vlan: 440, label: 'VLAN 440', location: @lax   unless Vlan.find_by(vlan: 440)
  end

  context 'next_available()' do
    specify 'should return next available VLAN' do
      expect(Vlan.next_available).to eq [103]
    end

    specify 'should not return a VLAN already in the VLAN database' do
      expect(Vlan.next_available).to_not eq([101])
    end

    specify 'should respect limit' do
      expect(Vlan.next_available(limit: 3)).to eq [103, 109, 110]
    end

    specify 'should respect start_at' do
      expect(Vlan.next_available(start_at: 400)).to eq [400]
      expect(Vlan.next_available(start_at: 440)).to eq [441]
    end
  end

  context 'in_use()' do
    before do
      Vlan.where('vlan > 440').delete_all
      @in_use = Vlan.in_use(@lax.id)
    end

    specify "should include all VLANs assigned in IpBlock's" do
      expect((@in_use & [102, 104, 105])).to eq [102, 104, 105]
    end

    specify 'should include all VLANs assigned in VLAN database' do
      expect((@in_use & [1, 101, 440])).to eq [1, 101, 440]
    end

    specify 'should be sorted and not return duplicates' do
      expect(@in_use).to eq [1, 100, 101, 102, 104, 105, 106, 107, 108, 440]
    end
  end
end
