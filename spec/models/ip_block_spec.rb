require 'rails_helper'

describe 'IpBlock class with fixtures loaded' do
  before do
    @ip_block  = IpBlock.new(cidr: '10.0.0.0/24')
    @ip_block6 = IpBlock.new(cidr: '2002::/64')
  end

  context 'when parent block is unrelated to block' do
    before do
      @ip_block2 = IpBlock.new(cidr: '10.0.0.0/24')
      @ip_block2.parent_block = IpBlock.new(cidr: '192.168.1.0/24')
    end

    specify 'should add an error' do
      @ip_block2.save
      expect(@ip_block2.errors).to_not be_empty
      expect(@ip_block2.errors[:parent_block]).to_not be_nil
    end
    specify 'should not be valid' do
      @ip_block2.save
      expect(@ip_block2.valid?).to eq(false)
    end
  end

  context 'when parent block is a supernet of block' do
    before do
      @ip_block = IpBlock.new(cidr: '10.0.0.0/25')
      @ip_block.parent_block = IpBlock.new(cidr: '10.0.0.0/24')
    end
    specify 'should be valid' do
      @ip_block.save
      expect(@ip_block.valid?).to eq(true)
    end
  end

  context 'gateway()' do
    specify 'should return gateway' do
      expect(@ip_block.gateway).to eq('10.0.0.1')
    end
  end

  context 'netmask()' do
    specify 'should return netmask in common format for IPv4' do
      expect(@ip_block.netmask).to eq('255.255.255.0')
    end
    specify "should return 'N/A' for IPv6" do
      expect(@ip_block6.netmask).to eq('N/A')
    end
  end

  context 'broadcast()' do
    specify 'should return broadcast for IPv4' do
      expect(@ip_block.broadcast).to eq('10.0.0.255')
    end
    specify "should return 'N/A' for IPv6" do
      expect(@ip_block6.broadcast).to eq('N/A')
    end
  end

  context 'ip_first()' do
    specify 'should return the first IP' do
      expect(@ip_block.ip_first).to eq('10.0.0.2')
    end
  end

  context 'ip_range_usable()' do
    specify 'should return the usable IP range for IPv4' do
      expect(@ip_block.ip_range_usable).to eq('10.0.0.2 - 10.0.0.254')
    end
    specify "should return 'N/A' for IPv6" do
      expect(@ip_block6.ip_range_usable).to eq('All except gateway (::1)')
    end
    specify 'should return just one IP, not range, if only one IP is usable' do
      @ip_block = IpBlock.new(cidr: '10.0.0.1/30')
      expect(@ip_block.ip_range_usable).to eq('10.0.0.2')
    end
  end

  context 'internal network representation' do
    specify 'should be set automatically on save' do
      @ip_block = IpBlock.new(cidr: '10.0.0.0/30')
      expect(@ip_block.network).to eq(nil)
      @ip_block.save
      expect(@ip_block.network).to eq(167_772_160)
    end
  end

  context 'cidr is blank' do
    before do
      @ip_block = IpBlock.new
    end

    specify 'ip_range_usable() should return nil' do
      expect(@ip_block.ip_range_usable).to be_nil
    end
    specify 'gateway() should return nil' do
      expect(@ip_block.gateway).to be_nil
    end
    specify 'netmask() should return nil' do
      expect(@ip_block.netmask).to be_nil
    end
    specify 'broadcast() should return nil' do
      expect(@ip_block.broadcast).to be_nil
    end
  end

  context 'subnetting' do
    before do
      @parent_block = IpBlock.create(cidr: '10.0.0.0/24')
      @child1 = IpBlock.create(cidr: '10.0.0.0/25', parent_block: @parent_block)
      @child2 = IpBlock.create(cidr: '10.0.0.128/27', parent_block: @parent_block)
    end

    context 'subnets()' do
      specify 'should return all subnets' do
        expect(@parent_block.subnets).to eq([@child1, @child2])
      end

      specify 'should return empty array if no subnets' do
        @parent_block = IpBlock.create(cidr: '172.16.0.1/24')
        expect(@parent_block.subnets).to eq([])
      end
    end

    context 'subnets_available()' do
      context 'shallow spec' do
        before do
          @mock_ip_allocator = double(IPAllocator)
          expect(IPAllocator).to receive(:new)\
            .with(@parent_block.cidr_obj, [@child1.cidr_obj, @child2.cidr_obj])\
            .and_return(@mock_ip_allocator)

          @prefixlen = 27
        end

        specify 'should ask for available blocks' do
          expect(@mock_ip_allocator).to receive(:available).with(@prefixlen, {}).and_return([])
          @parent_block.subnets_available(@prefixlen)
        end
      end

      context 'deep spec' do
        specify 'should return an array' do
          expect(@parent_block.subnets_available(27)).to be_kind_of(Array)
        end

        specify 'should return available subnets' do
          @available = @parent_block.subnets_available(27)

          expect(@available.map { |o| o.cidr }).to eq(\
            [IpBlock.new(cidr: '10.0.0.192/27').cidr,
             IpBlock.new(cidr: '10.0.0.160/27').cidr,
             IpBlock.new(cidr: '10.0.0.224/27').cidr]
          )
        end

        specify 'should return empty array if no subnets available' do
          expect(@parent_block.subnets_available(25)).to eq([])
        end

        specify 'should return empty array if prefixlen is a bad value' do
          expect(@parent_block.subnets_available('a')).to eq([])
        end

        context 'should return only limit records if limit specified' do
          specify 'as integer' do
            expect(@parent_block.subnets_available(27).size).to eq(3)
            expect(@parent_block.subnets_available(27, limit: 1).size).to eq(1)
          end

          specify 'as string' do
            expect(@parent_block.subnets_available(27).size).to eq 3
            expect(@parent_block.subnets_available(27, limit: '1').size).to eq 1
          end

          specify 'as empty string return all' do
            expect(@parent_block.subnets_available(27).size).to eq 3
            expect(@parent_block.subnets_available(27, limit: '').size).to eq 3
          end

          specify 'as negative integer return all' do
            expect(@parent_block.subnets_available(27).size).to eq 3
            expect(@parent_block.subnets_available(27, limit: -1).size).to eq 3
          end
        end
      end
    end
  end

  context 'account_name()' do
    let(:ip_block) do
      create :ip_block do |ipb|
        ipb.resource.service.account.first_name = 'John'
        ipb.resource.service.account.last_name = 'Doe'
      end
    end

    specify 'should return display_account_name for account that owns this IP block' do
      expect(ip_block.account_name).to eq('John Doe')
    end
  end

  context 'arin_network_name()' do
    context 'for IPv4' do
      specify "should return a string suitable for an ARIN SWIP 'Network Name' field" do
        expect(@ip_block.arin_network_name).to eq('ARPNET-10-0-0-0-24')
      end
    end

    context 'for IPv6' do
      before do
        @ip_block6 = IpBlock.new(cidr: '2607:f2f8:c0de::/48')
      end

      specify "should return a string suitable for an ARIN SWIP 'Network Name' field" do
        expect(@ip_block6.arin_network_name).to eq('ARPNET6-2607-F2F8-C0DE-48')
      end
    end
  end

  context 'origin_as()' do
    specify 'should return 25795' do
      expect(@ip_block.origin_as).to eq('25795')
    end
  end

  context 'reverse_dns_delegation_entries()' do
    context 'for IPv4' do
      specify 'should return text of entries suitable for BIND' do
        @ip_block = IpBlock.new(cidr: '10.0.0.1/28')
        expect(@ip_block.reverse_dns_delegation_entries(%w[foo bar])).to eq(<<~BLOCK
          ; BEGIN: RFC 2317 sub-Class C delegation
          ;
          0-15\t\tIN\tNS\tfoo.
          \t\tIN\tNS\tbar.
          ;
          2\t\tIN\tCNAME\t2.0-15.0.0.10.in-addr.arpa.
          3\t\tIN\tCNAME\t3.0-15.0.0.10.in-addr.arpa.
          4\t\tIN\tCNAME\t4.0-15.0.0.10.in-addr.arpa.
          5\t\tIN\tCNAME\t5.0-15.0.0.10.in-addr.arpa.
          6\t\tIN\tCNAME\t6.0-15.0.0.10.in-addr.arpa.
          7\t\tIN\tCNAME\t7.0-15.0.0.10.in-addr.arpa.
          8\t\tIN\tCNAME\t8.0-15.0.0.10.in-addr.arpa.
          9\t\tIN\tCNAME\t9.0-15.0.0.10.in-addr.arpa.
          10\t\tIN\tCNAME\t10.0-15.0.0.10.in-addr.arpa.
          11\t\tIN\tCNAME\t11.0-15.0.0.10.in-addr.arpa.
          12\t\tIN\tCNAME\t12.0-15.0.0.10.in-addr.arpa.
          13\t\tIN\tCNAME\t13.0-15.0.0.10.in-addr.arpa.
          14\t\tIN\tCNAME\t14.0-15.0.0.10.in-addr.arpa.
          ;
          ; END
        BLOCK
                                                                           )
      end
      specify 'only blocks smaller than /24 are supported' do
        @ip_block = IpBlock.new(cidr: '10.0.0.0/24')
        expect(@ip_block.reverse_dns_delegation_entries('foo')).to eq('Not supported: address block too larger (/24 or larger)')
      end
    end

    context 'for IPv6' do
      specify 'should return text of entries suitable for BIND' do
        @ip_block = IpBlock.new(cidr: 'fe80:1:c0de::/48')
        expect(@ip_block.reverse_dns_delegation_entries(%w[foo bar])).to eq(<<~BLOCK
          e.d.0.c    IN  NS  foo.
          e.d.0.c    IN  NS  bar.
        BLOCK
                                                                           )
      end
      specify 'only blocks of size /48 are supported' do
        @ip_block = IpBlock.new(cidr: 'fe80::/64')
        expect(@ip_block.reverse_dns_delegation_entries('foo')).to eq('Not supported: address block not equal to /48')
      end
    end
  end

  context 'rfc2317_zone_name()' do
    context 'for IPv4' do
      specify 'should return text of zone name' do
        @ip_block = IpBlock.new(cidr: '10.0.0.1/28')
        expect(@ip_block.rfc2317_zone_name).to eq('0-15.0.0.10.in-addr.arpa')
      end
    end
    context 'for IPv6' do
      specify 'does not apply to IPv6' do
        @ip_block = IpBlock.new(cidr: 'fe80::/64')
        expect(@ip_block.rfc2317_zone_name).to eq('Not applicable to IPv6')
      end
    end
  end

  context 'available_for_allocation()' do
    before do
      @location_code = 'lax'
    end

    context 'for IPv4' do
      specify 'smallest subnet is a /30' do
        expect(IpBlock.available_for_allocation(32, @location_code)).to eq('Only /30 and larger blocks are supported')
      end

      specify 'should find a /29' do
        ipb = create :ip_block, :available, cidr: '172.16.1.0/29', vlan: 106
        @location_code = ipb.location.code
        expect(IpBlock.available_for_allocation(29, @location_code)).to eq(ipb)
      end

      specify 'should find a /30' do
        ipb = create :ip_block, :available, cidr: '172.16.1.8/30', vlan: 107
        @location_code = ipb.location.code
        expect(IpBlock.available_for_allocation(30, @location_code)).to eq(ipb)
      end

      specify 'should not find a /27' do
        ipb = create :ip_block
        @location_code = ipb.location.code
        expect(IpBlock.available_for_allocation(27, @location_code)).to eq(nil)
      end
    end

    context 'for IPv6' do
      specify 'does not apply to IPv6' do
        expect(IpBlock.available_for_allocation(48, @location_code)).to eq('Not applicable to IPv6')
      end
    end
  end

  context 'reverse_dns_zone_name()' do
    context 'for IPv4' do
      specify 'should return text of zone name' do
        @ip_block = IpBlock.new(cidr: '10.0.0.1/28')
        expect(@ip_block.reverse_dns_zone_name).to eq('0.0.10.in-addr.arpa')
      end
    end
    context 'for IPv6' do
      specify 'should return text of zone name within ARP Networks /32' do
        @ip_block = IpBlock.new(cidr: '2607:f2f8:beef::/48')
        expect(@ip_block.reverse_dns_zone_name).to eq('8.f.2.f.7.0.6.2.ip6.arpa')
      end

      specify 'should return text of zone name within ARP Networks /29' do
        @ip_block = IpBlock.new(cidr: '2a07:12c0:beef::/48')
        expect(@ip_block.reverse_dns_zone_name).to eq('c.2.1.7.0.a.2.ip6.arpa')
      end

      specify 'should not return text of zone name if outside of ARP Networks /32' do
        @ip_block = IpBlock.new(cidr: 'fe80::/64')
        expect(@ip_block.reverse_dns_zone_name).to eq(nil)
      end
    end
  end

  context 'contains?()' do
    it 'should pass message to cidr_obj' do
      arg = 'foo'

      cidr_obj = double(:cidr_obj)
      expect(cidr_obj).to receive(:contains?).with(arg)

      ip = IpBlock.new
      expect(ip).to receive(:cidr_obj).and_return(cidr_obj)

      ip.contains?('foo')
    end
  end

  context 'self.account()' do
    RSpec.shared_examples 'finding containing network' do
      context 'with parent found' do
        before do
          @account = Account.new
          allow(@ip_blocks[0]).to receive(:contains?).and_return(false)
          allow(@ip_blocks[1]).to receive(:contains?).and_return(true)
          allow(@ip_blocks[1]).to receive(:account).and_return(@account)
          allow(@ip_blocks[2]).to receive(:contains?).and_return(false)
        end

        it 'should return account' do
          expect(go).to eq(@account)
        end
      end

      context 'without parent found' do
        before do
          @account = Account.new
          allow(@ip_blocks[0]).to receive(:contains?).and_return(false)
          allow(@ip_blocks[1]).to receive(:contains?).and_return(false)
          allow(@ip_blocks[2]).to receive(:contains?).and_return(false)
        end

        it 'should return nil' do
          expect(go).to eq(nil)
        end
      end
    end

    def go
      IpBlock.account(@ip)
    end

    context 'with valid v4 ip' do
      before do
        @ip = '10.0.0.15'
      end

      it 'should search for possible matches' do
        expect(IpBlock).to receive(:where).with(\
          "cidr like '10.0.0.%' and vlan >= 20"
        )\
                                          .and_return([])
        go
      end

      context 'with possible matches' do
        before do
          @ip_blocks = [
            IpBlock.new(cidr: '10.0.0.0/30'),
            IpBlock.new(cidr: '10.0.0.8/29'),
            IpBlock.new(cidr: '10.0.0.16/28')
          ]
          allow(IpBlock).to receive(:where).and_return(@ip_blocks)
        end

        it 'should iterate each for containment' do
          @ip_blocks.each do |ip_block|
            expect(ip_block).to receive(:contains?).with(@ip)
          end

          go
        end

        it_should_behave_like 'finding containing network'
      end
    end

    context 'with valid v6 ip' do
      before do
        @ip = '2607:f2f8:c123::2'
      end

      it 'should search for possible matches' do
        expect(IpBlock).to receive(:where).with(\
          "cidr like '2607:f2f8:c123:%' and vlan >= 20"
        )\
                                          .and_return([])
        go
      end

      context 'with possible matches' do
        before do
          @ip_blocks = [
            IpBlock.new(cidr: '2607:f2f8:c000::/48'),
            IpBlock.new(cidr: '2607:f2f8:c123::/48'),
            IpBlock.new(cidr: '2607:f2f8:c400::/48')
          ]
          allow(IpBlock).to receive(:where).and_return(@ip_blocks)
        end

        it 'should iterate each for containment' do
          @ip_blocks.each do |ip_block|
            expect(ip_block).to receive(:contains?).with(@ip)
          end
          go
        end

        it_should_behave_like 'finding containing network'
      end
    end

    context 'with invalid ip' do
      before do
        @ip = 'bleh'
      end

      it 'should return nil' do
        expect(IpBlock.account(@ip)).to eq(nil)
      end
    end

    context 'without ip' do
      before do
        @ip = nil
      end

      it 'should return return nil' do
        expect(IpBlock.account(@ip)).to eq(nil)
      end
    end
  end
end
