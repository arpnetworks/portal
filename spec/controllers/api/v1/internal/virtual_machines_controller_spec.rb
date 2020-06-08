require File.expand_path(File.dirname(__FILE__) + '/../../../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../../arp_spec_helper')

describe Api::V1::Internal::VirtualMachinesController do
  context 'handling POST /api/v1/internal/virtual_machines/phone_home/:uuid' do
    def do_post(opts = {})
      post :phone_home, { uuid: @UUID }.merge(opts)
    end

    context 'when VM UUID is invalid' do
      before do
        @UUID = 'something-non-existent'
        allow(VirtualMachine).to receive(:find_by).with(uuid: @UUID).and_return nil
      end

      it 'should return 404' do
        do_post
        expect(@response).to_not be_success
        expect(@response.status).to eq 404
      end
    end

    context 'with valid UUID' do
      before do
        @vm = build(:virtual_machine)
        @UUID = @vm.uuid
        allow(VirtualMachine).to receive(:find_by).with(uuid: @UUID).and_return @vm
      end

      it 'should set provisioning status to done' do
        expect(@vm.provisioning_status).to be_nil
        do_post
        expect(@vm.provisioning_status).to eq 'done'
      end
    end
  end
end
