require 'rails_helper'

describe Api::V1::Internal::VirtualMachinesController do
  context 'handling POST /api/v1/internal/virtual_machines/phone_home/:uuid' do
    def do_post(opts = {})
      post :phone_home, params: { uuid: @UUID }.merge(opts)
    end

    context 'when VM UUID is invalid' do
      before do
        @UUID = 'something-non-existent'
        allow(VirtualMachine).to receive(:find_by).with(uuid: @UUID).and_return nil
      end

      it 'should return 404' do
        do_post
        expect(@response).to_not be_successful
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

      context 'with SSH host keys' do
        before do
          @key_rsa = 'ssh-rsa AAAAA... root@example.com'
          @key_dsa = 'ssh-dsa AAAAA... root@example.com'
          @key_ecdsa = 'ssh-ecdsa AAAAA... root@example.com'
          @key_ed25519 = 'ssh-ed25519 AAAAA... root@example.com'

          @opts = {
            pub_key_rsa: @key_rsa,
            pub_key_dsa: @key_dsa,
            pub_key_ecdsa: @key_ecdsa,
            pub_key_ed25519: @key_ed25519
          }
        end

        context 'with existing set empty' do
          before do
            allow(@vm.ssh_host_keys).to receive(:empty?).and_return(true)
          end

          it 'should set host keys' do
            expect(@vm).to receive(:set_ssh_host_key).with(@key_rsa)
            expect(@vm).to receive(:set_ssh_host_key).with(@key_dsa)
            expect(@vm).to receive(:set_ssh_host_key).with(@key_ecdsa)
            expect(@vm).to receive(:set_ssh_host_key).with(@key_ed25519)

            do_post(@opts)

            expect(@response).to be_successful
          end
        end

        context 'with non-empty existing set' do
          before do
            allow(@vm.ssh_host_keys).to receive(:empty?).and_return(false)
            allow(@vm).to receive(:update)
          end

          it 'should not set host keys' do
            expect(@vm).to_not receive(:set_ssh_host_key)
            expect(@vm).to_not receive(:set_ssh_host_key)
            expect(@vm).to_not receive(:set_ssh_host_key)
            expect(@vm).to_not receive(:set_ssh_host_key)

            do_post(@opts)

            expect(@response).to be_successful
          end
        end
      end
    end
  end
end
