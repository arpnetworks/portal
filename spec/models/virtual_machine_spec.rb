require File.dirname(__FILE__) + '/../rails_helper'

context VirtualMachine do
  before do
    @uuid = '1234'
    @service = create :service
    @vm = create :virtual_machine
    @vm.resource.service = @service
  end

  context 'DNS records' do
    before :context do
      DnsRecord.delete_all
      DnsDomain.delete_all

      DnsDomain.create(name: 'arpnetworks.com', type: 'NATIVE')

      # Create a few accounts because we want an account ID > 1
      create :account
      create :account
      @account = create :account

      @ip_address   = '10.0.0.1'
      @ipv6_address = 'fe80::2'
    end

    after :context do
      DnsDomain.find_by_name('arpnetworks.com').destroy
    end

    specify 'should be created upon VM creation with IPs assigned' do
      label = 'bar'
      record_name = "#{label}.cust.arpnetworks.com"

      expect(DnsRecord.find_by_name(record_name)).to be_nil

      @vm = create :virtual_machine, {
        uuid: @uuid,
        label: label
      }

      @vm.virtual_machines_interfaces[0].update_attributes(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save

      dns_record = DnsRecord.find_by_name_and_type(record_name, 'A')
      expect(dns_record).to_not be_nil
      expect(dns_record.content).to eq @ip_address

      dns_record = DnsRecord.find_by_name_and_type(record_name, 'AAAA')
      expect(dns_record).to_not be_nil
      expect(dns_record.content).to eq @ipv6_address
    end

    specify 'should be updated upon VM label change' do
      @vm.virtual_machines_interfaces[0].update_attributes(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      label = 'a-new-label'
      @vm.label = label
      @vm.save

      expect(v4_record.reload.name).to eq "#{label}.cust.arpnetworks.com"
      expect(v6_record.reload.name).to eq "#{label}.cust.arpnetworks.com"
    end

    specify 'should be updated upon IP address change' do
      @vm.virtual_machines_interfaces[0].update_attributes(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      ipv4 = '192.168.0.1'
      ipv6 = 'fe80::3'

      @vm.virtual_machines_interfaces[0].ip_address = ipv4
      @vm.virtual_machines_interfaces[0].ipv6_address = ipv6
      @vm.save

      expect(v4_record.reload.content).to eq ipv4
      expect(v6_record.reload.content).to eq ipv6
    end
    specify 'should not update when VM label does not change' do
      @vm = VirtualMachine.first
      ipv4_address = @vm.virtual_machines_interfaces[0].ip_address
      ipv6_address = @vm.virtual_machines_interfaces[0].ipv6_address

      # Should not receive :update_attributes
      ipv4_dns_record_mock = mock_model(DnsRecord,
                                        name: @vm.dns_record_name,
                                        content: ipv4_address)
      ipv6_dns_record_mock = mock_model(DnsRecord,
                                        name: @vm.dns_record_name,
                                        content: ipv6_address)

      expect(DnsRecord).to receive(:find_by_name_and_type).with(@vm.dns_record_name, 'A').at_least(:once) \
        { ipv4_dns_record_mock }
      expect(DnsRecord).to receive(:find_by_name_and_type).with(@vm.dns_record_name, 'AAAA').at_least(:once) \
        { ipv6_dns_record_mock }

      @vm.save
    end
    specify 'should be deleted upon VM destruction' do
      @vm.virtual_machines_interfaces[0].update_attributes(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      expect(v4_record).to_not be_nil
      expect(v6_record).to_not be_nil

      @vm.destroy

      expect(DnsRecord.find_by_id(v4_record.id)).to be_nil
      expect(DnsRecord.find_by_id(v6_record.id)).to be_nil
    end

    specify 'should not be created upon VM creation belonging to ARP Networks' do
      expect(DnsDomain).to_not receive(:find_by_name)

      @vm = create :virtual_machine, {
        uuid: @uuid,
        label: 'baz'
      }

      begin
        @account = Account.find 1
      rescue
        @account = create(:account, id: 1)
      end

      @vm.resource.service.account = @account

      @vm.virtual_machines_interfaces.create
      @vm.virtual_machines_interfaces[0].update_attributes(
        ip_address: '10.0.0.1',
        ipv6_address: 'fe80::2'
      )
      @vm.save
    end
    specify 'should not be updated upon VM label change belonging to ARP Networks' do
      expect(DnsDomain).to_not receive(:find_by_name)

      @vm = create :virtual_machine

      begin
        @account = Account.find 1
      rescue
        @account = create(:account, id: 1)
      end

      @vm.resource.service.account = @account

      ipv4 = '192.168.0.1'
      ipv6 = 'fe80::3'
      @vm.virtual_machines_interfaces.create
      @vm.virtual_machines_interfaces[0].ip_address = ipv4
      @vm.virtual_machines_interfaces[0].ipv6_address = ipv6
      @vm.save
    end
  end

  context 'dns_record_name()' do
    specify 'should be of the form <label>.cust.arpnetworks.com' do
      expect(@vm.dns_record_name).to eq "#{@vm.label}.cust.arpnetworks.com"
    end
    specify 'should be of the form <alt-label>.cust.arpnetworks.com if we supply <alt-label>' do
      expect(@vm.dns_record_name('alt')).to eq 'alt.cust.arpnetworks.com'
    end
  end

  ##################################
  # BEGIN: Testing of Resourceable #
  ##################################

  # I wrote these specs when the code in Resourceable was actually in VirtualMachine
  # (it was born there).

  context 'when creating' do
    context 'with service_id' do
      specify 'should assign VM to service' do
        @vm = VirtualMachine.create(uuid: @uuid,
                                    service_id: @service.id,
                                    host: 'foo.arpnetworks.com',
                                    ram: 1024,
                                    storage: 20,
                                    label: 'foo')

        @vm = VirtualMachine.find_by_uuid(@uuid) # Reload the whole instance

        expect(@vm.resource.service).to eq @service
      end
    end
  end

  context 'when updating' do
    context 'with service_id' do
      before do
        @service_new = create :service
      end

      def do_reassign
        @vm.service_id = @service_new.id
        @vm.save
      end

      specify 'should remove from old service' do
        # Test both directions first
        expect(@vm.resource.service).to eq @service
        @service.virtual_machines.first == @vm

        # Reassign
        do_reassign
        @vm.reload

        # VM should not belong to @service anymore
        @service.virtual_machines.each do |vm|
          expect(vm).to_not eq @vm
        end
        expect(@vm.resource.service).to_not eq @service
      end

      specify 'should assign VM to service' do
        do_reassign
        expect(@vm.resource.service).to eq @service_new
      end

      context 'when no prior service was assigned' do
        specify 'should assign VM to service' do
          @vm = VirtualMachine.create(uuid: @uuid,
                                      service_id: @service.id,
                                      host: 'foo.arpnetworks.com',
                                      ram: 1024,
                                      storage: 20,
                                      label: 'foo2')

          expect(@vm.resource).to_not be_nil
          do_reassign
          expect(@vm.resource.service).to eq @service_new
        end
      end
    end
  end

  context 'when VM belongs to' do
    context 'a service' do
      specify 'service_id() should return parent service' do
        expect(@vm.service_id).to eq @service.id
      end
    end
  end

  ################################
  # END: Testing of Resourceable #
  ################################
end
