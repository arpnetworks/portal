require File.dirname(__FILE__) + '/../rails_helper'

context VirtualMachine do
  before do
    @uuid = '1234'
    @service = create :service
    @vm = create :virtual_machine
  end

  context "DNS records" do
    before :context do
      DnsRecord.delete_all
      DnsDomain.create(:name => 'arpnetworks.com')
    end

    after :context do
      DnsDomain.find_by_name('arpnetworks.com').destroy
    end

    specify "should be created upon VM creation with IPs assigned" do
      label = 'foo'
      record_name = "#{label}.cust.arpnetworks.com"
      ip_address = '10.0.0.1'
      ipv6_address = 'fe80::2'

      DnsRecord.find_by_name(record_name).should == nil
      @vm = VirtualMachine.create(:uuid => @uuid,
                                  :service_id => @service.id,
                                  :label => label)
      @vm.virtual_machines_interfaces[0].update_attributes(
        :ip_address => ip_address,
        :ipv6_address => ipv6_address
      )
      @vm.save

      dns_record = DnsRecord.find_by_name_and_type(record_name, 'A')
      dns_record.should_not be_nil
      dns_record.content.should == ip_address

      dns_record = DnsRecord.find_by_name_and_type(record_name, 'AAAA')
      dns_record.should_not be_nil
      dns_record.content.should == ipv6_address
    end
    specify "should be updated upon VM label change" do
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      label = 'a-new-label'
      @vm.label = label
      @vm.save

      v4_record.reload.name.should == "#{label}.cust.arpnetworks.com"
      v6_record.reload.name.should == "#{label}.cust.arpnetworks.com"
    end
    specify "should be updated upon IP address change" do
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      ipv4 = '192.168.0.1'
      ipv6 = 'fe80::3'
      @vm.virtual_machines_interfaces[0].ip_address = ipv4
      @vm.virtual_machines_interfaces[0].ipv6_address = ipv6
      @vm.save

      v4_record.reload.content.should == ipv4
      v6_record.reload.content.should == ipv6
    end
    specify "should not update when VM label does not change" do
      @vm = VirtualMachine.find(1)
      ipv4_address = @vm.virtual_machines_interfaces[0].ip_address
      ipv6_address = @vm.virtual_machines_interfaces[0].ipv6_address

      # Should not receive :update_attributes
      ipv4_dns_record_mock = mock_model(DnsRecord,
                                        :name => @vm.dns_record_name,
                                        :content => ipv4_address)
      ipv6_dns_record_mock = mock_model(DnsRecord,
                                        :name => @vm.dns_record_name,
                                        :content => ipv6_address)

      DnsRecord.should_receive(:find_by_name_and_type).with(@vm.dns_record_name, 'A').\
        and_return(ipv4_dns_record_mock)
      DnsRecord.should_receive(:find_by_name_and_type).with(@vm.dns_record_name, 'AAAA').\
        and_return(ipv6_dns_record_mock)

      @vm.save
    end
    specify "should be deleted upon VM destruction" do
      @vm.save # This will create the initial records

      v4_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'A')
      v6_record = DnsRecord.find_by_name_and_type(@vm.dns_record_name, 'AAAA')

      v4_record.should_not be_nil
      v6_record.should_not be_nil

      @vm.destroy

      DnsRecord.find_by_id(v4_record.id).should == nil
      DnsRecord.find_by_id(v6_record.id).should == nil
    end

    specify "should not be created upon VM creation belonging to ARP Networks" do
      DnsDomain.should_not_receive(:find_by_name)

      @vm = VirtualMachine.create(:uuid => @uuid,
                                  :service_id => services(:garrys_vps),
                                  :label => 'foo')
      @vm.virtual_machines_interfaces[0].update_attributes(
        :ip_address => '10.0.0.1',
        :ipv6_address => 'fe80::2'
      )
      @vm.save
    end
    specify "should not be updated upon VM label change belonging to ARP Networks" do
      DnsDomain.should_not_receive(:find_by_name)

      @vm = virtual_machines(:garrys_vm)
      ipv4 = '192.168.0.1'
      ipv6 = 'fe80::3'
      @vm.virtual_machines_interfaces.create
      @vm.virtual_machines_interfaces[0].ip_address = ipv4
      @vm.virtual_machines_interfaces[0].ipv6_address = ipv6
      @vm.save
    end
  end

  context "dns_record_name()" do
    specify "should be of the form <label>.cust.arpnetworks.com" do
      @vm.dns_record_name.should == "johndoe.cust.arpnetworks.com"
    end
    specify "should be of the form <alt-label>.cust.arpnetworks.com if we supply <alt-label>" do
      @vm.dns_record_name('alt').should == 'alt.cust.arpnetworks.com'
    end
  end

  ##################################
  # BEGIN: Testing of Resourceable #
  ##################################

  # I wrote these specs when the code in Resourceable was actually in VirtualMachine
  # (it was born there).

  context "when creating" do
    context "with service_id" do
      specify "should assign VM to service" do
        @vm = VirtualMachine.create(:uuid => @uuid,
                                    :service_id => @service.id,
                                    :label => 'foo')
        @vm = VirtualMachine.find_by_uuid(@uuid) # Reload the whole instance
        @vm.resource.service.should == @service
      end
    end
  end

  context "when updating" do
    context "with service_id" do

      before do
        @service_new = services(:garrys_vps)
      end

      def do_reassign
        @vm.service_id = @service_new.id
        @vm.save
      end

      specify "should remove from old service" do
        # Test both directions first
        @vm.resource.service.should == @service
        @service.virtual_machines.first == @vm

        # Reassign
        do_reassign
        @vm.reload

        # VM should not belong to @service anymore
        @service.virtual_machines.each do |vm|
          vm.should_not == @vm
        end
        @vm.resource.service.should_not == @service
      end

      specify "should assign VM to service" do
        do_reassign
        @vm.resource.service.should == @service_new
      end

      context "when no prior service was assigned" do
        specify "should assign VM to service" do
          @vm = VirtualMachine.create(:uuid => @uuid,
                                      :label => 'foo')
          @vm.resource.should be_nil
          do_reassign
          @vm.resource.service.should == @service_new
        end
      end
    end
  end

  context "when VM belongs to" do
    context "a service" do
      specify "service_id() should return parent service" do
        @vm.service_id.should == @service.id
      end
    end
  end


  ################################
  # END: Testing of Resourceable #
  ################################
end
