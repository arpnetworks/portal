require File.dirname(__FILE__) + '/../rails_helper'

describe Account do
  # fixtures :accounts, :service_codes, :services, :resources, :virtual_machines
  # TODO

  let(:account) do
    create :account do |a|
      a.login = 'garry2'
      a.first_name = 'Garry'
      a.last_name = 'Dolley'
      a.email = 'garry2@garry.com'
      a.password = '76dfcef085f1664858228a075da17af9d0c3610b'
    end
  end

  describe "display_name()" do
    before do
      @first_name = 'FooBar'
      @company    = 'myBiz'
    end

    it "should use company instead of first_name or login if not nil" do
      account.company = @company
      expect(account.display_name).to eq(@company)
    end

    it "should use first_name instead of login if not nil" do
      account.first_name = @first_name
      expect(account.display_name).to eq(@first_name)
    end

    it "should use login if first_name is nil" do
      account.first_name = nil
      expect(account.display_name).to eq(account.login)
    end

    it "should not use a blank company name" do
      account.first_name = @first_name
      account.company = ""
      expect(account.display_name).to eq(@first_name)
    end

    it "should not use a blank first_name name" do
      account.first_name = ""
      expect(account.display_name).to eq(account.login)
    end
  end

  describe "display_account_name()" do
    before do
      @first_name = 'FooBar'
      @company    = 'myBiz'
      @last_name  = account.last_name
    end

    it "should use company instead of first_name or login if not nil" do
      account.company = @company
      expect(account.display_account_name).to eq(@company)
    end

    it "should use first_name + last_name instead of login if not nil" do
      account.first_name = @first_name
      expect(account.display_account_name).to eq("#{@first_name} #{@last_name}")
    end

    it "should use login if first_name is nil" do
      account.first_name = nil
      expect(account.display_account_name).to eq(account.login)
    end

    it "should not use a blank company name" do
      account.first_name = @first_name
      account.company = ""
      expect(account.display_account_name).to eq("#{@first_name} #{@last_name}")
    end

    it "should not use a blank first_name name" do
      account.first_name = ""
      expect(account.display_account_name).to eq(account.login)
    end
  end

  describe "find_virtual_machine_by_id()" do
    before do
      @garrys_vm = create :virtual_machine
      create :service, account: account, virtual_machines: [@garrys_vm]
    end

    context "when it is my VM" do
      it "should find my VM" do
        expect(account.find_virtual_machine_by_id(@garrys_vm.id)).to \
          eq(@garrys_vm)
      end
    end

    context "when it is not my VM" do
      it "should return nil" do
        expect(account.find_virtual_machine_by_id(1)).to eq(nil)
      end
    end
  end

  describe "find_backup_quota_by_id()" do
    before do
      @garrys_bq = create :backup_quota
      create :service, account: account, backup_quotas: [@garrys_bq]
    end

    context "when it is my VM" do
      it "should find my VM" do
        expect(account.find_backup_quota_by_id(@garrys_bq.id)).to \
          eq(@garrys_bq)
      end
    end

    context "when it is not my VM" do
      it "should return nil" do
        expect(account.find_backup_quota_by_id(1)).to eq(nil)
      end
    end
  end

  describe "suspend!()" do
    before do
      @account = Factory.create(:account_garry)
      @account.suspend!
    end

    it "should mark VLAN shutdown" do
      @account.vlan_shutdown_at.should_not be_nil
    end

    it "should cause Account to be suspended" do
      @account.suspended?.should == true
    end
  end

  describe "unsuspend!()" do
    before do
      @account = Factory.create(:account_garry)
      @account.suspend!
    end

    it "should mark VLAN as not shutdown" do
      @account.vlan_shutdown_at.should_not be_nil
      @account.unsuspend!
      @account.vlan_shutdown_at.should == nil
    end

    it "should cause Account to not be suspended" do
      @account.suspended?.should == true
      @account.unsuspend!
      @account.suspended?.should == false
    end
  end

  context "IPs and DNS Records" do
    before do
      ServiceCode.delete_all

      @ip_blocks = [Factory.create(:ip_block, :cidr => '10.0.0.0/30'),
                    Factory.create(:ip_block, :cidr => '2607:f2f8:d00d::/48'),
                    Factory.create(:ip_block, :cidr => '192.168.0.0/29'),
                    Factory.create(:ip_block, :cidr => '2607:f2f8:beef::/48')]

      @account = Factory.create(:account)
      @service_code = Factory.create(:service_code_for_ip_block)

      Factory.create(:service,
                     :account => @account,
                     :service_code => @service_code,
                     :ip_blocks => @ip_blocks)
      Factory.create(:service,
                     :account => @account) # Some other non-IP service
    end

    describe "ip_block()" do
      it "should return service with IP_BLOCK service code belonging to this account" do
        @account.ip_block.should == Service.find_by_service_code_id_and_account_id(@service_code.id, @account.id)
      end

      it "should not return an IP_BLOCK service if the service has been deleted" do
        ip_block_service = @account.ip_block
        ip_block_service.destroy
        @account.ip_block.should == nil
      end
    end

    describe "ip_blocks()" do
      it "should return all IpBlock records associated with this account" do
        @account.ip_blocks.should == @ip_blocks
      end

      it "should not return an IpBlock if its service has been deleted" do
        new_ip_block = Factory.create(:ip_block, :cidr => '172.16.1.1/28')
        service = Factory.create(:service,
                                 :account => @account,
                                 :service_code => @service_code,
                                 :ip_blocks => [new_ip_block])
        @account.ip_blocks.should == [@ip_blocks, new_ip_block].flatten
        service.destroy
        @account.ip_blocks.should == @ip_blocks
      end
    end

    describe "vlan()" do
      it "should return ID of VLAN associated with this account" do
        @account.vlan.should == 999
      end

      it "should return nil if no IP blocks are associated with this account" do
        @account = Factory.create(:account) # New account without IP blocks
        @account.vlan.should == nil
      end
    end

    describe "owns_dns_record?()" do
      specify "should return true if dns_record is a PTR and belongs to account" do
        @dns_record_for_me = \
          Factory.create(:dns_record,
                         :name => '2.0.0.10.in-addr.arpa',
                         :content => 'example.com')
        @dns_record_for_me.type = 'PTR'
        @account.owns_dns_record?(@dns_record_for_me).should == true
      end

      specify "should return false if dns_record is a PTR and does not belongs to account" do
        @dns_record_for_someone_else = \
          Factory.create(:dns_record,
                         :name => '9.0.0.10.in-addr.arpa',
                         :content => 'example.com')
        @dns_record_for_someone_else.type = 'PTR'
        @account.owns_dns_record?(@dns_record_for_someone_else).should == false
      end

      specify "should return true if dns_record is a CNAME and belongs to account" do
        @dns_record_for_me = \
          Factory.create(:dns_record,
                         :name => '2.0.0.10.in-addr.arpa',
                         :content => 'example.com')

        DnsRecord.delete_all("type != 'CNAME'")
        @dns_record_for_me.type = 'CNAME'
        @account.owns_dns_record?(@dns_record_for_me).should == true
      end

      specify "should return false if dns_record is a CNAME and does not belongs to account" do
        @dns_record_for_someone_else = \
          Factory.create(:dns_record,
                         :name => '9.0.0.10.in-addr.arpa',
                         :content => 'example.com')
        @dns_record_for_someone_else.type = 'CNAME'
        @account.owns_dns_record?(@dns_record_for_someone_else).should == false
      end

      specify "should return false if dns_record is a PTR and IPv4 IP is the network number" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => '0.0.0.10.in-addr.arpa',
                        :content => 'example.com')
        @dns_record.type = 'PTR'
        @account.owns_dns_record?(@dns_record).should == false
      end

      specify "should return false if dns_record is a PTR and IPv4 IP is the first IP (gateway)" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => '1.0.0.10.in-addr.arpa',
                        :content => 'example.com')
        @dns_record.type = 'PTR'
        @account.owns_dns_record?(@dns_record).should == false
      end

      specify "should return false if dns_record is a PTR and IPv4 IP is the last IP (broadcast)" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => '3.0.0.10.in-addr.arpa',
                        :content => 'example.com')
        @dns_record.type = 'PTR'
        @account.owns_dns_record?(@dns_record).should == false
      end

      specify "should return true if dns_record is IPv6 and name is a prefix match" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => 'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                        :content => 'ns1.example.com')
        @dns_record.type = 'NS'
        @account.owns_dns_record?(@dns_record).should == true
      end

      specify "should return true if dns_record is IPv6 and name is a prefix match (test #2)" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => 'd.e.a.d.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                        :content => 'ns1.example.com')
        @dns_record.type = 'NS'
        @account.owns_dns_record?(@dns_record).should == true
      end

      specify "should return true if dns_record is an RFC 2317 style NS record that belongs to account" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => '0-3.0.0.10.in-addr.arpa',
                        :content => 'ns1.example.com')
        @dns_record.type = 'NS'
        @account.owns_dns_record?(@dns_record).should == true
      end

      specify "should return true if dns_record is an RFC 2317 style NS record that belongs to account (using /29 block)" do
        @dns_record = \
          Factory.build(:dns_record,
                        :name => '0-7.0.168.192.in-addr.arpa',
                        :content => 'ns1.example.com')
        @dns_record.type = 'NS'
        @account.owns_dns_record?(@dns_record).should == true
      end
    end

    describe "reverse_dns_zones()" do
      specify "should return an array of zones in which this account may create records" do
        @account.reverse_dns_zones.should ==
          ["0.0.10.in-addr.arpa", 
           "0.168.192.in-addr.arpa",
           "d.0.0.d.8.f.2.f.7.0.6.2.ip6.arpa",
           "f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa"]
      end

      specify "should return IPv4 blocks before IPv6 blocks" do
        @account.reverse_dns_zones.should ==
          ["0.0.10.in-addr.arpa", 
           "0.168.192.in-addr.arpa",
           "d.0.0.d.8.f.2.f.7.0.6.2.ip6.arpa",
           "f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa"]
      end
    end
  end

  context "Bandwidth Quota" do
    before do
      Account.delete_all("id > 2")

      @account = Factory.create(:account_garry)
      @garrys_bq = Factory.create(:bandwidth_quota)
      Factory.create(:service,
                     :account => @account,
                     :bandwidth_quotas => [@garrys_bq])
    end

    describe "bandwidth_quotas()" do
      it "should return all BandwidthQuota records associated with this account" do
        @account.bandwidth_quotas.should == [@garrys_bq]
      end

      it "should not return a BandwidthQuota if its service has been deleted" do
        new_bandwidth_quota = Factory.create(:bandwidth_quota)
        service = Factory.create(:service,
                                 :account => @account,
                                 :bandwidth_quotas => [new_bandwidth_quota])
        @account.bandwidth_quotas.should == [@garrys_bq, new_bandwidth_quota].flatten
        service.destroy
        @account.bandwidth_quotas.should == [@garrys_bq]
      end
    end
  end
end

describe Account, "with Tender integration" do
  fixtures :accounts

  describe "tender_token()" do
    it "should return valid token" do
      expiry = 1.week.from_now
      valid_token = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("SHA1"),
                                            Account::TENDER_SECRET,
                                            "#{Tender::TENDER_HOST}/garry2@garry.com/#{expiry}")

      account = Factory.build(:account_garry)
      account.tender_token(expiry).should == valid_token
    end
  end
end
