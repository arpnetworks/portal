require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

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
      DnsDomain.find_by(name: 'arpnetworks.com').destroy
    end

    specify 'should be created upon VM creation with IPs assigned' do
      label = 'bar'
      record_name = "#{label}.cust.arpnetworks.com"

      expect(DnsRecord.find_by(name: record_name)).to be_nil

      @vm = create :virtual_machine, {
        uuid: @uuid,
        label: label
      }

      @vm.virtual_machines_interfaces[0].update(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save

      dns_record = DnsRecord.find_by(name: record_name, type: 'A')
      expect(dns_record).to_not be_nil
      expect(dns_record.content).to eq @ip_address

      dns_record = DnsRecord.find_by(name: record_name, type: 'AAAA')
      expect(dns_record).to_not be_nil
      expect(dns_record.content).to eq @ipv6_address
    end

    specify 'should be updated upon VM label change' do
      @vm.virtual_machines_interfaces[0].update(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'A')
      v6_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'AAAA')

      label = 'a-new-label'
      @vm.label = label
      @vm.save

      expect(v4_record.reload.name).to eq "#{label}.cust.arpnetworks.com"
      expect(v6_record.reload.name).to eq "#{label}.cust.arpnetworks.com"
    end

    specify 'should be updated upon IP address change' do
      @vm.virtual_machines_interfaces[0].update(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'A')
      v6_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'AAAA')

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
      @vm.virtual_machines_interfaces[0].update(
        ip_address: @ip_address,
        ipv6_address: @ipv6_address
      )

      @vm.resource.service.account = @account
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'A')
      v6_record = DnsRecord.find_by(name: @vm.dns_record_name, type: 'AAAA')

      expect(v4_record).to_not be_nil
      expect(v6_record).to_not be_nil

      @vm.destroy

      expect(DnsRecord.find_by(id: v4_record.id)).to be_nil
      expect(DnsRecord.find_by(id: v6_record.id)).to be_nil
    end

    specify 'should not be created upon VM creation belonging to ARP Networks' do
      expect(DnsDomain).to_not receive(:find_by_name)

      @vm = create :virtual_machine, {
        uuid: @uuid,
        label: 'baz'
      }

      begin
        @account = Account.find 1
      rescue StandardError
        @account = create(:account, id: 1)
      end

      @vm.resource.service.account = @account

      @vm.virtual_machines_interfaces.create
      @vm.virtual_machines_interfaces[0].update(
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
      rescue StandardError
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

        @vm = VirtualMachine.find_by(uuid: @uuid) # Reload the whole instance

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

  describe 'set_ssh_host_key()' do
    before do
      @vm = build(:virtual_machine)
    end

    context 'with RSA key' do
      before do
        @ssh_host_key = 'ssh-rsa AAAA... foo'
        @key_type = 'rsa'
      end

      it 'should create a key' do
        expect(@vm.ssh_host_keys).to receive(:create).with(key: @ssh_host_key)
        @vm.set_ssh_host_key(@ssh_host_key)
      end
    end

    context 'with N/A key from cloud-init' do
      before do
        @ssh_host_key = 'N/A'
      end

      it 'should not create a key' do
        expect(@vm.ssh_host_keys).to_not receive(:create)
        @vm.set_ssh_host_key(@ssh_host_key)
      end
    end

    context 'with blank key' do
      before do
        @ssh_host_key = ''
      end

      it 'should not create a key' do
        expect(@vm.ssh_host_keys).to_not receive(:create)
        @vm.set_ssh_host_key(@ssh_host_key)
      end
    end
  end

  context 'display_ip_address()' do
    before do
      @ip_address = '10.0.0.1'
    end

    context 'without VM interfaces' do
      before do
        allow(@vm).to receive(:virtual_machines_interfaces).and_return([])
      end

      it 'should return no available info' do
        expect(@vm.display_ip_address).to eq 'Not Available'
      end
    end

    context 'with VM interfaces' do
      before do
        allow(@vm.virtual_machines_interfaces.first).to receive(:ip_address).and_return @ip_address
      end

      context 'with non-empty IP address' do
        it 'should return IP address' do
          expect(@vm.display_ip_address).to eq @ip_address
        end
      end

      context 'with nil IP address' do
        before do
          allow(@vm.virtual_machines_interfaces.first).to receive(:ip_address).and_return nil
        end

        it 'should return no available info' do
          expect(@vm.display_ip_address).to eq 'Not Available'
        end
      end

      context 'with blank IP address' do
        before do
          allow(@vm.virtual_machines_interfaces.first).to receive(:ip_address).and_return ''
        end

        it 'should return no available info' do
          expect(@vm.display_ip_address).to eq 'Not Available'
        end
      end
    end
  end

  context 'self.os_display_name_from_code()' do
    before do
      @cloud_os_struct_yaml = <<-YAML
        cloud_os:
          freebsd:
            title: FreeBSD
            series:
              - version: '12.1'
                code: 'freebsd-12.1-amd64'
              - version: '11.3'
                code: 'freebsd-11.3-amd64'
          openbsd:
            title: OpenBSD
            series:
              - version: '6.6'
                code: 'openbsd-6.6-amd64'
                pending: true
          ubuntu:
            title: Ubuntu Linux
            series:
              - version: '20.04'
                code: 'ubuntu-20.04-amd64'
      YAML

      @cloud_os_struct = YAML.safe_load(@cloud_os_struct_yaml)['cloud_os']
    end

    context 'with freebsd-12.1-amd64 code' do
      before do
        @code = 'freebsd-12.1-amd64'
      end

      it 'should return FreeBSD' do
        expect(VirtualMachine.os_display_name_from_code(@cloud_os_struct, @code)).to eq 'FreeBSD'
      end

      context 'with desired version' do
        before do
          @opts = { version: true }
        end

        it 'should return FreeBSD 12.1' do
          expect(VirtualMachine.os_display_name_from_code(@cloud_os_struct, @code, @opts)).to eq 'FreeBSD 12.1'
        end
      end
    end

    context 'with openbsd-6.6-amd64 code' do
      before do
        @code = 'openbsd-6.6-amd64'
      end

      it 'should return OpenBSD' do
        expect(VirtualMachine.os_display_name_from_code(@cloud_os_struct, @code)).to eq 'OpenBSD'
      end

      context 'with desired version' do
        before do
          @opts = { version: true }
        end

        it 'should return OpenBSD 6.6' do
          expect(VirtualMachine.os_display_name_from_code(@cloud_os_struct, @code, @opts)).to eq 'OpenBSD 6.6'
        end
      end
    end

    context 'with non-existent code' do
      before do
        @code = 'centos-8.1-amd64'
      end

      it 'should return nil' do
        expect(VirtualMachine.os_display_name_from_code(@cloud_os_struct, @code)).to be_nil
      end
    end
  end
end
