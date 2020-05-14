require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

context DnsRecordsController do

  before(:context) do
    Account.delete_all
    Service.delete_all
    ServiceCode.delete_all
    Resource.delete_all

    @account = create_user!

    @ip_blocks = [create(:ip_block, cidr: '10.0.0.0/30'),
                  create(:ip_block, cidr: '192.168.0.0/29'),
                  create(:ip_block, cidr: '2607:f2f8:beef::/48')]

    service = Service.create(account: @account,
                             service_code: create(:service_code))

    service.ip_blocks << @ip_blocks
    create(:service, account: @account) # Some other service
  end

  before do
    @account = login_as_user!
  end

  specify 'should be a DnsRecordsController' do
    expect(controller).to be_an_instance_of(DnsRecordsController)
  end

  specify 'account should have two services' do
    expect(@account.services.size).to eq 2
  end

  context 'handling GET /accounts/1/reverse_dns' do
    def do_get(opts = {})
      get :reverse_dns, { account_id: @account.id }.merge(opts)
    end

    specify 'should be a success' do
      do_get
      expect(response).to be_success
    end

    specify 'should be a success even if account has no IP blocks' do
      account = create :account
      login_with_account!(account)
      expect(account.ip_blocks).to eq []
      do_get(account_id: account.id)
      expect(response).to be_success
    end

    specify 'should retrieve IP blocks' do
      do_get
      expect(assigns(:ip_blocks)).to eq @ip_blocks
    end

    context 'when building records' do
      before do
        DnsRecord.delete_all

        @dns_records = []

        @dns_records << create(:dns_record, :the_10_block,
                               name: '2.0.0.10.in-addr.arpa',
                               content: 'example.com')
      end

      specify 'should build records with same name and different type' do
        # Same name, different type
        @dns_records << create(:dns_record_with_ns_type, :the_10_block,
                               name: '2.0.0.10.in-addr.arpa',
                               content: 'example.com')
        do_get
        expect(assigns(:records).sort { |a,b| a.ip <=> b.ip }).to eq [
          OpenStruct.new({
            r_id: @dns_records[0].id,
            ip: '10.0.0.2',
            name: '2.0.0.10.in-addr.arpa',
            r_type: 'PTR',
            content: 'example.com.' }),
          OpenStruct.new({
            r_id: @dns_records[1].id,
            ip: '10.0.0.2',
            name: '2.0.0.10.in-addr.arpa',
            r_type: 'NS',
            content: 'example.com' })
        ].sort { |a,b| a.ip <=> b.ip }
      end

      specify 'should build records for RFC 2317 delegations' do
        rfc2317_record = build :dns_record, :the_10_block,
                                             name: '0-3.0.0.10.in-addr.arpa',
                                             content: 'ns1.example.com'
        rfc2317_record.type = 'NS'
        allow(rfc2317_record).to receive(:domain).and_return(double(DnsDomain, increment_serial!: true))
        rfc2317_record.save

        @dns_records << rfc2317_record

        do_get
        expect(assigns(:records)).to eq [
          OpenStruct.new({
            r_id: @dns_records[0].id,
            ip: '10.0.0.2',
            name: '2.0.0.10.in-addr.arpa',
            r_type: 'PTR',
            content: 'example.com.' }),
          OpenStruct.new({
            r_id: @dns_records[1].id,
            name: '0-3.0.0.10.in-addr.arpa',
            r_type: 'NS',
            content: 'ns1.example.com' })
        ]
      end

      specify 'should only build records belonging to account' do
        # Add a couple more than @account owns
        (2..8).each do |n|
          @dns_records << create(:dns_record, :the_192_block,
                                              name: "#{n}.0.168.192.in-addr.arpa",
                                              content: "foo#{n}")
        end

        do_get
        expect(assigns(:records)).to eq [
          OpenStruct.new({
            r_id: @dns_records[0].id,
            ip: '10.0.0.2',
            name: '2.0.0.10.in-addr.arpa',
            r_type: 'PTR',
            content: 'example.com.' }),
          OpenStruct.new({
            r_id: @dns_records[1].id,
            ip: '192.168.0.2',
            name: '2.0.168.192.in-addr.arpa',
            r_type: 'PTR',
            content: 'foo2.' }),
          OpenStruct.new({
            r_id: @dns_records[2].id,
            ip: '192.168.0.3',
            name: '3.0.168.192.in-addr.arpa',
            r_type: 'PTR',
            content: 'foo3.' }),
          OpenStruct.new({
            r_id: @dns_records[3].id,
            ip: '192.168.0.4',
            name: '4.0.168.192.in-addr.arpa',
            r_type: 'PTR',
            content: 'foo4.' }),
          OpenStruct.new({
            r_id: @dns_records[4].id,
            ip: '192.168.0.5',
            name: '5.0.168.192.in-addr.arpa',
            r_type: 'PTR',
            content: 'foo5.' }),
          OpenStruct.new({
            r_id: @dns_records[5].id,
            ip: '192.168.0.6',
            name: '6.0.168.192.in-addr.arpa',
            r_type: 'PTR',
            content: 'foo6.' })
        ]
      end

      specify 'should only build IPv6 records belonging to account' do
        @domain_ipv6 = create(:dns_domain,
                              name: '8.f.2.f.7.0.6.2.ip6.arpa')

        # Belongs to @account
        @dns_records << create(:dns_record,
                               dns_domain: @domain_ipv6,
                               name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                               content: 'example.com')
        @dns_records << create(:dns_record,
                               dns_domain: @domain_ipv6,
                               name: '3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                               content: 'example2.com')

        # Belongs to someone else
        @dns_records << create(:dns_record,
                               dns_domain: @domain_ipv6,
                               name: '3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.c.8.f.2.f.7.0.6.2.ip6.arpa',
                               content: 'example2.com')


        do_get
        expect(assigns(:records_ipv6)).to eq [
          OpenStruct.new({
            r_id: @dns_records[1].id,
            name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
            r_type: 'PTR',
            content: 'example.com.'
          }),
          OpenStruct.new({
            r_id: @dns_records[2].id,
            name: '3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
            r_type: 'PTR',
            content: 'example2.com.'
          })
        ]
      end

      specify 'should build IPv6 records with same name and different type' do
        @domain_ipv6 = create(:dns_domain,
                              name: '8.f.2.f.7.0.6.2.ip6.arpa')

        # Belongs to @account
        @dns_records << create(:dns_record,
                               dns_domain: @domain_ipv6,
                               name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                               content: 'example.com')
        @dns_records << create(:dns_record_with_ns_type,
                               dns_domain: @domain_ipv6,
                               name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
                               content: 'example2.com')

        do_get
        expect(assigns(:records_ipv6)).to eq [
          OpenStruct.new({
            r_id: @dns_records[1].id,
            name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
            r_type: 'PTR',
            content: 'example.com.'
          }),
          OpenStruct.new({
            r_id: @dns_records[2].id,
            name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
            r_type: 'NS',
            content: 'example2.com'
          })
        ]
      end
    end
  end

  context 'RESTful actions' do
    before do
      DnsRecord.delete_all

      @dns_record = create(:dns_record, :the_10_block,
                           name: '2.0.0.10.in-addr.arpa',
                           content: 'example.com')

      @params = { id: @dns_record.id }
    end

    describe 'handling GET /account/1/dns_record/1/new' do
      def do_get(opts = {})
        get :new, { account_id: @account.id }.merge(opts)
      end

      it 'should display new dns_record form' do
        do_get
        expect(assigns(:dns_record)).to be_new_record
        expect(response).to be_success
      end

      it 'should set default type to PTR' do
        do_get
        expect(assigns(:dns_record).type).to eq 'PTR'
        expect(response).to be_success
      end

      it 'should redirect back if account has no reverse DNS zones' do
        account_without_zones = create(:account)
        login_with_account!(account_without_zones)
        do_get(account_id: account_without_zones.id)
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(account_without_zones))
        expect(flash[:error]).to_not be_nil
      end
    end

    describe 'handling POST /accounts/1/dns_records' do
      def do_post(opts = {})
        post :create, { account_id: @account.id }.merge(opts)
      end

      it 'should create new dns_record' do
        allow(@account).to receive(:owns_dns_record?) { true }
        num_records = DnsRecord.count
        new_dns_record = {
          name: '2',
          domain: '0.0.10.in-addr.arpa',
          type: 'PTR',
          content: 'example.com'
        }
        do_post(@params.merge(dns_record: new_dns_record))
        expect(DnsRecord.count).to eq(num_records + 1)
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
        expect(flash[:notice]).to_not be_nil
      end

      it 'should create new IPv6 dns_record' do
        create :dns_domain, :the_ipv6_block
        allow(@account).to receive(:owns_dns_record?) { true }
        num_records = DnsRecord.count
        new_dns_record = {
          name: '2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0',
          domain: 'f.e.e.b.8.f.2.f.7.0.6.2.ip6.arpa',
          type: 'PTR',
          content: 'example.com'
        }
        do_post(@params.merge(dns_record: new_dns_record))
        expect(DnsRecord.count).to eq(num_records + 1)
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
        expect(flash[:notice]).to_not be_nil
      end

      it 'should assign new dns_record to correct domain' do
        domain = DnsDomain.find_by_name('0.0.10.in-addr.arpa') || create(:dns_domain, :the_10_block)
        new_dns_record = {
          name: '2',
          domain: domain.name,
          type: 'PTR',
          content: 'example.com'
        }
        do_post(@params.merge(dns_record: new_dns_record))
        expect(assigns(:dns_record).domain).to eq domain
      end

      it 'should go back to new page if error creating' do
        dns_record_mock = mock_model(DnsRecord,
                                     :ip => '10.0.0.1',
                                     :type => 'NS',
                                     :save => false,
                                     :name => '1.0.0.10.in-addr.arpa',
                                     :[] => 'foo',
                                     :domain_id => 1,
                                     :domain_id= => true,
                                     :domain => build(:dns_record, :the_10_block))
        expect(DnsRecord).to receive(:new).and_return(dns_record_mock)
        do_post(@params.merge(dns_record: { name: 'foo' }))
        expect(response).to render_template('dns_records/new')
      end

      it 'should strip domain from name if error' do
        new_dns_record = {
          name: '1',
          domain: '0.0.10.in-addr.arpa',
          type: 'PTR',
          content: 'example.com'
        }
        do_post(@params.merge(dns_record: new_dns_record))
        expect(assigns(:dns_record)[:name]).to eq '1'
      end

      it 'should strip domain from name if error even if name is empty' do
        new_dns_record = {
          name: '',
          domain: '0.0.10.in-addr.arpa',
          type: 'NS',
          content: 'ns1.example.com'
        }
        do_post(@params.merge(dns_record: new_dns_record))
        expect(assigns(:dns_record)[:name]).to eq ''
      end

      it 'should not allow creation of dns_record that account could not own' do
        num_records = DnsRecord.count

        new_dns_record = {
          name: '240',
          domain: '0.0.10.in-addr.arpa',
          type: 'PTR',
          content: 'example.com'
        }

        do_post(@params.merge(dns_record: new_dns_record))
        expect(DnsRecord.count).to eq num_records
        expect(assigns(:dns_record).errors[:name]).to_not be_nil
        expect(assigns(:dns_record).errors[:name].first).to match(/is not within your IP range/)
        expect(response).to render_template('dns_records/new')
      end

      it 'should send NOTIFYs' do
        new_dns_record = {
          name: '2',
          domain: '0.0.10.in-addr.arpa',
          type: 'PTR',
          content: 'example.com'
        }
        expect(@controller).to receive(:send_notify).with('0.0.10.in-addr.arpa')
        do_post(@params.merge(dns_record: new_dns_record))
      end
    end

    context 'handling GET /accounts/1/dns_records/1/edit' do
      def do_get(opts = {})
        get :edit, { account_id: @account.id }.merge(opts)
      end

      it 'should show the dns_record' do
        do_get @params
        expect(response).to be_success
        expect(assigns(:dns_record).id).to eq @dns_record.id
      end

      it 'should redirect when the dns_record is not found' do
        do_get @params.merge(id: 999)
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
      end

      it 'should redirect when the dns_record does not belong to account' do
        @dns_record_for_someone_else = \
          create(:dns_record, :the_10_block,
                  name: '9.0.0.10.in-addr.arpa',
                  content: 'example.com')
        do_get @params.merge(id: @dns_record_for_someone_else.id)
        expect(flash[:error]).to_not be_nil
        expect(flash[:error]).to match(/You do not have permissions to edit/)
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
      end
    end

    context 'handling PUT /accounts/1/dns_records/1/edit' do
      def do_put(opts = {})
        put :update, { account_id: @account.id }.merge(opts)
      end

      it 'should update the dns_record' do
        new_content = 'example2.com.'
        expect(@dns_record.content).to_not eq new_content
        do_put(@params.merge(dns_record: { type: 'PTR',
                                              content: new_content }))
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
        expect(flash[:notice]).to_not be_empty

        @reloaded_dns_record = DnsRecord.find(@dns_record.id)
        expect(@reloaded_dns_record.content).to eq new_content
      end

      it 'should go back to edit page if error updating' do
        do_put(@params.merge(id: @dns_record.id, dns_record: { type: 'BAD' }))
        expect(response).to render_template('dns_records/edit')
      end

      it 'should redirect when the dns_record is not found' do
        do_put @params.merge(id: 999)
        expect(flash[:error]).to_not be_nil
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
      end

      it 'should send NOTIFYs' do
        new_content = 'example2.com.'
        expect(@dns_record.content).to_not eq new_content
        expect(@controller).to receive(:send_notify).with('0.0.10.in-addr.arpa')
        do_put(@params.merge(dns_record: { type: 'PTR',
                                              content: new_content }))
      end

      it 'should not update dns_record if resulting record could not be owned by account' do
        new_name = '0-3.0.0.10.in-addr.arpa'
        do_put @params.merge(dns_record: { name: new_name, type: 'NS',
                                              content: @dns_record.content.chop })
        expect(flash[:notice]).to eq 'Changes saved.'
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))

        dns_record = DnsRecord.find(@dns_record.id)
        dns_record.name = new_name
        allow(DnsRecord).to receive(:find).and_return(dns_record)
        # Now that we make type a CNAME, it can't have RFC 2317 style record name
        # (that is, the record could not be owned by this account)
        do_put @params.merge(dns_record: { name: new_name, type: 'CNAME',
                                              content: @dns_record.content.chop })
        expect(response).to render_template('dns_records/edit')
      end
    end

    describe 'handling DELETE /accounts/1/dns_records/1' do
      def do_destroy(opts = {})
        put :destroy, { account_id: @account.id }.merge(opts)
      end

      def mock_dns_record(stubs={})
        @mock_dns_record ||= mock_model(DnsRecord, { ip: '10.0.0.1',
                                                     type: 'NS',
                                                     domain: build(:dns_domain, :the_10_block),
                                                     content: 'foo.com',
                                                     name: '1.0.0.10.in-addr.arpa' }.merge(stubs))
      end

      it 'should destroy the requested dns_records' do
        expect(DnsRecord).to receive(:find).with('37').and_return(mock_dns_record)
        expect(mock_dns_record).to receive(:destroy)
        do_destroy(id: '37')
      end

      it 'should redirect back to dns records index' do
        allow(DnsRecord).to receive(:find) { mock_dns_record(destroy: true) }
        do_destroy(id: '1')
        expect(response).to redirect_to(reverse_dns_account_dns_records_path(@account))
      end

      it 'should set flash[:error] if destroy() raises AR exception' do
        bad_monkey = mock_model(DnsRecord, ip: '10.0.0.1',
                                           type: 'NS',
                                           domain: build(:dns_domain, :the_10_block),
                                           content: 'foo.com',
                                           name: '1.0.0.10.in-addr.arpa')
        expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'u no good')
        allow(DnsRecord).to receive(:find).and_return(bad_monkey)
        do_destroy(id: '1')
        expect(flash[:error]).to_not be_nil
      end

      it 'should send NOTIFYs' do
        expect(@controller).to receive(:send_notify).with('0.0.10.in-addr.arpa')
        expect(DnsRecord).to receive(:find).with('37') { mock_dns_record }
        expect(mock_dns_record).to receive(:destroy)
        do_destroy(id: '37')
      end
    end
  end

  context 'send_notify()' do
    before do
      allow(Kernel).to receive(:system).and_return(nil)
    end

    def do_send_notify(domain)
      DnsRecordsController.new.instance_eval do
        send_notify(domain)
      end
    end

    specify 'should execute shell command for pdns to send a NOTIFY to slaves' do
      domain = '0.0.10.in-addr.arpa'
      expect(Kernel).to receive(:system).with('pdns_control', 'notify', domain)
      do_send_notify(domain)
    end
  end
end
