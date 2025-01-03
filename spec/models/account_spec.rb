require 'rails_helper'

describe Account do
  it_behaves_like 'two_factor_authenticatable'
  it_behaves_like 'two_factor_backupable'

  describe '#login' do
    it { should validate_presence_of(:login) }
    it { should validate_uniqueness_of(:login).case_insensitive }
    it { should validate_length_of(:login).is_at_least(3).is_at_most(48) }

    it { should     allow_value('john').for(:login) }
    it { should     allow_value('john123').for(:login) }
    it { should     allow_value('123john').for(:login) }
    it { should     allow_value('john_123').for(:login) }
    it { should     allow_value('john-123').for(:login) }
    it { should     allow_value('john ').for(:login) } # Devise auto stripe whitespace before validation
    it { should     allow_value("john\n").for(:login) } # Devise auto stripe whitespace before validation
    it { should_not allow_value('john@').for(:login) }
    it { should_not allow_value('john?').for(:login) }
    it { should_not allow_value('john*').for(:login) }

    it 'auto stripe whitespace for login before validation' do
      account = Account.new(login: " john\n")
      account.validate
      expect(account.login).to eq('john')
    end
  end

  describe '#email' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it { should     allow_value('john@test.com').for(:email) }
    it { should     allow_value('JOHN@TEST.COM').for(:email) } # Allow upper case
    it { should     allow_value('john@test.co').for(:email) } # Allow the suffix with two characters
    it { should     allow_value('john@test-test.com').for(:email) } # Allow the host name with "-"
    it { should     allow_value('john@test123.com').for(:email) } # Allow the host name with number
    it { should     allow_value(' john@test.com').for(:email) } # Devise atuo stripe whitespace before validation
    it { should     allow_value("\njohn@test.com").for(:email) } # Devise atuo stripe whitespace before validation
    it { should_not allow_value('john@test.c').for(:email) } # Disallow suffix with one character
    it { should_not allow_value('john@testcom').for(:email) } # Disallow host without "."
    it { should_not allow_value('j@hn@testcom').for(:email) } # Disallow name with "@"

    it 'auto stripe whitespace for email before validation' do
      account = Account.new(email: " john@test.com\n")
      account.validate
      expect(account.email).to eq('john@test.com')
    end
  end

  describe '#password' do
    it { should validate_length_of(:password).is_at_least(8) }
    it { should validate_presence_of(:password) }
    it { should validate_confirmation_of(:password) }
  end

  %w[email2 email_billing].each do |field|
    describe "##{field}" do
      it { should     allow_value(nil).for(:email2) } # Allow blank
      it { should     allow_value('').for(:email2) } # Allow blank
      it { should     allow_value(' ').for(:email2) } # Allow blank
      it { should     allow_value('john@test.com').for(:email2) }
      it { should     allow_value('JOHN@TEST.COM').for(:email2) } # Allow upper case
      it { should     allow_value('john@test.co').for(:email2) } # Allow the suffix with two characters
      it { should     allow_value('john@test-test.com').for(:email2) } # Allow the host name with "-"
      it { should     allow_value('john@test123.com').for(:email2) } # Allow the host name with number
      it { should_not allow_value(' john@test.com').for(:email2) } # Disallow space
      it { should_not allow_value("\njohn@test.com").for(:email2) } # Disallow "\n"
      it { should_not allow_value('john@test.c').for(:email2) } # Disallow suffix with one character
      it { should_not allow_value('john@testcom').for(:email2) } # Disallow host without "."
      it { should_not allow_value('j@hn@testcom').for(:email2) } # Disallow name with "@"
    end
  end

  let(:account) do
    create :account do |a|
      a.login = 'garry2'
      a.first_name = 'Garry'
      a.last_name = 'Dolley'
      a.email = 'garry2@garry.com'
      a.legacy_encrypted_password = '76dfcef085f1664858228a075da17af9d0c3610b'
    end
  end

  describe 'display_name()' do
    before do
      @first_name = 'FooBar'
      @company    = 'myBiz'
    end

    it 'should use company instead of first_name or login if not nil' do
      account.company = @company
      expect(account.display_name).to eq(@company)
    end

    it 'should use first_name instead of login if not nil' do
      account.first_name = @first_name
      expect(account.display_name).to eq(@first_name)
    end

    it 'should use login if first_name is nil' do
      account.first_name = nil
      expect(account.display_name).to eq(account.login)
    end

    it 'should not use a blank company name' do
      account.first_name = @first_name
      account.company = ''
      expect(account.display_name).to eq(@first_name)
    end

    it 'should not use a blank first_name name' do
      account.first_name = ''
      expect(account.display_name).to eq(account.login)
    end
  end

  describe 'display_account_name()' do
    before do
      @first_name = 'FooBar'
      @company    = 'myBiz'
      @last_name  = account.last_name
    end

    it 'should use company instead of first_name or login if not nil' do
      account.company = @company
      expect(account.display_account_name).to eq(@company)
    end

    it 'should use first_name + last_name instead of login if not nil' do
      account.first_name = @first_name
      expect(account.display_account_name).to eq("#{@first_name} #{@last_name}")
    end

    it 'should use login if first_name is nil' do
      account.first_name = nil
      expect(account.display_account_name).to eq(account.login)
    end

    it 'should not use a blank company name' do
      account.first_name = @first_name
      account.company = ''
      expect(account.display_account_name).to eq("#{@first_name} #{@last_name}")
    end

    it 'should not use a blank first_name name' do
      account.first_name = ''
      expect(account.display_account_name).to eq(account.login)
    end
  end

  describe 'find_virtual_machine_by_id()' do
    before do
      @garrys_vm = create :virtual_machine
      create :service, account: account, virtual_machines: [@garrys_vm]
    end

    context 'when it is my VM' do
      it 'should find my VM' do
        expect(account.find_virtual_machine_by_id(@garrys_vm.id)).to \
          eq(@garrys_vm)
      end
    end

    context 'when it is not my VM' do
      it 'should return nil' do
        expect(account.find_virtual_machine_by_id(1)).to eq(nil)
      end
    end
  end

  describe 'find_backup_quota_by_id()' do
    before do
      @garrys_bq = create :backup_quota
      create :service, account: account, backup_quotas: [@garrys_bq]
    end

    context 'when it is my VM' do
      it 'should find my VM' do
        expect(account.find_backup_quota_by_id(@garrys_bq.id)).to \
          eq(@garrys_bq)
      end
    end

    context 'when it is not my VM' do
      it 'should return nil' do
        expect(account.find_backup_quota_by_id(1)).to eq(nil)
      end
    end
  end

  describe 'suspend!()' do
    before do
      account.suspend!
    end

    it 'should mark VLAN shutdown' do
      expect(account.vlan_shutdown_at).to_not be_nil
    end

    it 'should cause Account to be suspended' do
      expect(account.suspended?).to eq(true)
    end
  end

  describe 'unsuspend!()' do
    before do
      account.suspend!
    end

    it 'should mark VLAN as not shutdown' do
      expect(account.vlan_shutdown_at).to_not be_nil
      account.unsuspend!
      expect(account.vlan_shutdown_at).to be_nil
    end

    it 'should cause Account to not be suspended' do
      expect(account.suspended?).to eq(true)
      account.unsuspend!
      expect(account.suspended?).to eq(false)
    end
  end

  describe 'in_stripe?()' do
    context 'when stripe_customer_id is nil' do
      before :each do
        account.stripe_customer_id = nil
      end

      it 'should return false' do
        expect(account.in_stripe?).to eq false
      end
    end

    context 'when stripe_customer_id is blank' do
      before do
        account.stripe_customer_id = ''
      end

      it 'should return false' do
        expect(account.in_stripe?).to eq false
      end
    end

    context 'when stripe_customer_id is not empty' do
      before do
        account.stripe_customer_id = 'cus_Kj1sZ4oXZPkeeq'
      end

      it 'should return true' do
        expect(account.in_stripe?).to eq true
      end
    end
  end

  describe 'offload_billing?()' do
    context 'when stripe_payment_method_id is nil' do
      before :each do
        account.stripe_payment_method_id = nil
      end

      it 'should return false' do
        expect(account.offload_billing?).to eq false
      end
    end

    context 'when stripe_payment_method_id is blank' do
      before do
        account.stripe_payment_method_id = ''
      end

      it 'should return false' do
        expect(account.offload_billing?).to eq false
      end
    end

    context 'when stripe_payment_method_id is not empty' do
      before do
        account.stripe_payment_method_id = 'pm_foo'
      end

      it 'should return true' do
        expect(account.offload_billing?).to eq true
      end
    end
  end

  describe 'bootstrap_stripe!' do
    context 'when account is not in Stripe' do
      before :each do
        allow(account).to receive(:in_stripe?).and_return false
      end

      it 'should bootstrap our Stripe subscription' do
        @stripe_subscription = double(StripeSubscriptionWithoutValidation)
        expect(StripeSubscriptionWithoutValidation).to receive(:new).with(account)\
                                                                    .and_return @stripe_subscription
        expect(@stripe_subscription).to receive(:bootstrap!)
        account.bootstrap_stripe!
      end
    end
  end

  describe 'stripe_subscription()' do
    it 'should return our StripeSubscription for this account' do
      @stripe_sub = double(StripeSubscription)
      expect(StripeSubscription).to receive(:new).with(account).and_return @stripe_sub
      expect(account.stripe_subscription).to eq @stripe_sub
    end
  end

  describe 'arc()' do
    context 'with interval = 1' do
      before :each do
        @interval = 1
      end

      it 'should simply call mrc()' do
        expect(account).to receive(:mrc)
        account.arc @interval
      end
    end

    context 'with interval = 6' do
      before :each do
        @interval = 6
      end

      it 'should call mrc() with the stated interval' do
        expect(account).to receive(:mrc).with(interval: @interval)
        account.arc @interval
      end
    end
  end

  describe 'yrc()' do
    it 'should call arc() with 12' do
      expect(account).to receive(:arc).with(12)
      account.yrc
    end
  end

  context 'IPs and DNS Records' do
    before do
      @ip_blocks = [create(:ip_block, cidr: '10.0.0.0/30'),
                    create(:ip_block, cidr: '2607:f2f8:d00d::/48'),
                    create(:ip_block, cidr: '192.168.0.0/29'),
                    create(:ip_block, cidr: '2607:f2f8:beef::/48')]

      @service_code = create :service_code_for_ip_block

      create :service, account: account, service_code: @service_code, ip_blocks: @ip_blocks

      create :service, account: account # Some other non-IP service
    end

    describe 'ip_block()' do
      it 'should return service with IP_BLOCK service code belonging to this account' do
        expect(account.ip_block).to eq(Service.find_by(service_code_id: @service_code.id, account_id: account.id))
      end

      it 'should not return an IP_BLOCK service if the service has been deleted' do
        ip_block_service = account.ip_block
        ip_block_service.destroy
        expect(account.ip_block).to eq(nil)
      end
    end

    describe 'ip_blocks()' do
      it 'should return all IpBlock records associated with this account' do
        expect(account.ip_blocks).to eq(@ip_blocks)
      end

      it 'should not return an IpBlock if its service has been deleted' do
        new_ip_block = create :ip_block, cidr: '172.16.1.1/28'
        service = create :service, account: account,
                                   service_code: @service_code,
                                   ip_blocks: [new_ip_block]

        expect(account.ip_blocks).to eq([@ip_blocks, new_ip_block].flatten)
        service.destroy
        expect(account.ip_blocks).to eq(@ip_blocks)
      end
    end

    describe 'vlan()' do
      it 'should return ID of VLAN associated with this account' do
        @vlan = account.ip_blocks.first.vlan
        expect(account.vlan).to eq(@vlan)
      end

      it 'should return nil if no IP blocks are associated with this account' do
        account = create :account
        expect(account.vlan).to eq(nil)
      end
    end

    describe 'owns_dns_record?()' do
      specify 'should return true if dns_record is a PTR and belongs to account' do
        @dns_record_for_me = create :dns_record, :the_10_block, name: '2.0.0.10.in-addr.arpa',
                                                                content: 'example.com'
        @dns_record_for_me.type = 'PTR'
        expect(account.owns_dns_record?(@dns_record_for_me)).to eq(true)
      end

      specify 'should return false if dns_record is a PTR and does not belongs to account' do
        @dns_record_for_someone_else = create :dns_record, :the_10_block, name: '9.0.0.10.in-addr.arpa',
                                                                          content: 'example.com'
        @dns_record_for_someone_else.type = 'PTR'
        expect(account.owns_dns_record?(@dns_record_for_someone_else)).to eq(false)
      end

      specify 'should return true if dns_record is a CNAME and belongs to account' do
        @dns_record_for_me = create :dns_record, :the_10_block, name: '2.0.0.10.in-addr.arpa',
                                                                content: 'example.com'

        DnsRecord.where("type != 'CNAME'").delete_all
        @dns_record_for_me.type = 'CNAME'
        expect(account.owns_dns_record?(@dns_record_for_me)).to be(true)
      end

      specify 'should return false if dns_record is a CNAME and does not belongs to account' do
        @dns_record_for_someone_else = create :dns_record, :the_10_block, name: '9.0.0.10.in-addr.arpa',
                                                                          content: 'example.com'
        expect(account.owns_dns_record?(@dns_record_for_someone_else)).to eq(false)
      end

      specify 'should return false if dns_record is a PTR and IPv4 IP is the network number' do
        @dns_record = build :dns_record, :the_10_block, name: '0.0.0.10.in-addr.arpa',
                                                        content: 'example.com'
        @dns_record.type = 'PTR'
        expect(account.owns_dns_record?(@dns_record)).to eq(false)
      end

      specify 'should return false if dns_record is a PTR and IPv4 IP is the first IP (gateway)' do
        @dns_record = build :dns_record, name: '1.0.0.10.in-addr.arpa',
                                         content: 'example.com'
        @dns_record.type = 'PTR'
        expect(account.owns_dns_record?(@dns_record)).to eq(false)
      end

      specify 'should return false if dns_record is a PTR and IPv4 IP is the last IP (broadcast)' do
        @dns_record = build :dns_record, name: '3.0.0.10.in-addr.arpa',
                                         content: 'example.com'
        @dns_record.type = 'PTR'
        expect(account.owns_dns_record?(@dns_record)).to eq(false)
      end

      specify 'should return true if dns_record is IPv6 and name is a prefix match' do
        @dns_record = build :dns_record, name: 'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                                         content: 'ns1.example.com'
        @dns_record.type = 'NS'
        expect(account.owns_dns_record?(@dns_record)).to eq(true)
      end

      specify 'should return true if dns_record is IPv6 and name is a prefix match (test #2)' do
        @dns_record = build :dns_record, name: 'd.e.a.d.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                                         content: 'ns1.example.com'
        @dns_record.type = 'NS'
        expect(account.owns_dns_record?(@dns_record)).to eq(true)
      end

      specify 'should return true if dns_record is an RFC 2317 style NS record that belongs to account' do
        @dns_record = build :dns_record, name: '0-3.0.0.10.in-addr.arpa',
                                         content: 'ns1.example.com'
        @dns_record.type = 'NS'
        expect(account.owns_dns_record?(@dns_record)).to eq(true)
      end

      specify 'should return true if dns_record is an RFC 2317 style NS record that belongs to account (using /29 block)' do
        @dns_record = build :dns_record, name: '0-7.0.168.192.in-addr.arpa',
                                         content: 'ns1.example.com'
        @dns_record.type = 'NS'
        expect(account.owns_dns_record?(@dns_record)).to eq(true)
      end
    end

    describe 'reverse_dns_zones()' do
      specify 'should return an array of zones in which this account may create records' do
        expect(account.reverse_dns_zones).to eq(\
          ['0.0.10.in-addr.arpa',
           '0.168.192.in-addr.arpa',
           'd.0.0.d.8.f.2.f.7.0.6.2.ip6.arpa',
           'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa']
        )
      end

      specify 'should return IPv4 blocks before IPv6 blocks' do
        expect(account.reverse_dns_zones).to eq(\
          ['0.0.10.in-addr.arpa',
           '0.168.192.in-addr.arpa',
           'd.0.0.d.8.f.2.f.7.0.6.2.ip6.arpa',
           'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa']
        )
      end
    end
  end

  context 'Bandwidth Quota' do
    before do
      Account.where('id > 2').delete_all

      @garrys_bq = create :bandwidth_quota
      create :service, account: account, bandwidth_quotas: [@garrys_bq]
    end

    describe 'bandwidth_quotas()' do
      it 'should return all BandwidthQuota records associated with this account' do
        expect(account.bandwidth_quotas).to eq([@garrys_bq])
      end

      it 'should not return a BandwidthQuota if its service has been deleted' do
        new_bandwidth_quota = create :bandwidth_quota
        service = create :service, account: account, bandwidth_quotas: [new_bandwidth_quota]

        expect(account.bandwidth_quotas).to eq([@garrys_bq, new_bandwidth_quota].flatten)
        service.destroy
        expect(account.bandwidth_quotas).to eq([@garrys_bq])
      end
    end
  end

  describe '#otp_qrcode' do
    it 'successfully generates a RQRCode::QRCode object' do
      account = Account.new(login: 'john')
      account.otp_secret = Account.generate_otp_secret
      qrcode = account.otp_qrcode

      assert qrcode.is_a?(RQRCode::QRCode)
      assert_match(/svg version="1\.1"/, qrcode.as_svg)
    end
  end

  describe '.create_from_new_order!' do
    let(:customer) do
      {
        first_name: 'John',
        last_name: 'Lidström',
        email: 'john@example.com',
        company: 'Hockey Corp',
        address1: '123 Main St',
        address2: 'Suite 100',
        city: 'Detroit',
        state: 'MI',
        postal_code: '48201',
        country: 'US'
      }
    end

    before do
      # Stub save to return self (the account instance) without actually saving
      allow_any_instance_of(Account).to receive(:save) { |account| account }
      # Stub exists? to control the uniqueness check
      allow(Account).to receive(:exists?).and_return(false)
      # Stub mailer to do nothing
      mailer = double('Mailer')
      allow(mailer).to receive(:deliver_later)
      allow(Mailer).to receive(:welcome_new_customer).and_return(mailer)
    end

    it 'creates login by transliterating Unicode characters' do
      account = Account.create_from_new_order!(customer)
      expect(account.login).to eq('johnlidstrom')
    end

    it 'handles multiple Unicode characters' do
      customer[:first_name] = 'José'
      customer[:last_name] = 'Señor'
      account = Account.create_from_new_order!(customer)
      expect(account.login).to eq('josesenor')
    end

    it 'appends number to login if already taken' do
      # Mock first check to return true (login exists) then false (login with number doesn't exist)
      allow(Account).to receive(:exists?).and_return(true, false)
      account = Account.create_from_new_order!(customer)
      expect(account.login).to eq('johnlidstrom1')
    end
  end
end

describe Account, 'with Tender integration' do
  describe 'tender_token()' do
    it 'should return valid token' do
      expiry = 1.week.from_now
      valid_token = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA1'),
                                            Account::TENDER_SECRET,
                                            "#{Tender::TENDER_HOST}/garry2@garry.com/#{expiry}")

      account = build :account do |a|
        a.login = 'garry2'
        a.first_name = 'Garry'
        a.last_name = 'Dolley'
        a.email = 'garry2@garry.com'
        a.password = '76dfcef085f1664858228a075da17af9d0c3610b'
      end

      expect(account.tender_token(expiry)).to eq(valid_token)
    end
  end
end
