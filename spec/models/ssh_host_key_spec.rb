require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

context SshHostKey do
  context 'with an SSH host key' do
    describe 'generate_fingerprints()' do
      it 'should generate and save SHA256 fingerprint'
      it 'should generate and save MD5 fingerprint'
    end

    describe 'set_key_type()' do
      context 'with RSA key' do
        before do
          @ssh_host_key = build(:ssh_host_key, key: 'ssh-rsa AAAA... foo')
        end

        it 'should set key_type to rsa' do
          expect(@ssh_host_key.key_type).to be_nil
          @ssh_host_key.send(:set_key_type)
          expect(@ssh_host_key.key_type).to eq 'rsa'
        end
      end

      context 'with DSA key' do
        before do
          @ssh_host_key = build(:ssh_host_key, key: 'ssh-dsa AAAA... foo')
        end

        it 'should set key_type to dsa' do
          expect(@ssh_host_key.key_type).to be_nil
          @ssh_host_key.send(:set_key_type)
          expect(@ssh_host_key.key_type).to eq 'dsa'
        end
      end

      context 'with ECDSA key' do
        before do
          @ssh_host_key = build(:ssh_host_key, key: 'ssh-ecdsa AAAA... foo')
        end

        it 'should set key_type to ecdsa' do
          expect(@ssh_host_key.key_type).to be_nil
          @ssh_host_key.send(:set_key_type)
          expect(@ssh_host_key.key_type).to eq 'ecdsa'
        end
      end

      context 'with ED25519 key' do
        before do
          @ssh_host_key = build(:ssh_host_key, key: 'ssh-ed25519 AAAA... foo')
        end

        it 'should set key_type to ed25519' do
          expect(@ssh_host_key.key_type).to be_nil
          @ssh_host_key.send(:set_key_type)
          expect(@ssh_host_key.key_type).to eq 'ed25519'
        end
      end

      context 'with unrecognized key' do
        before do
          @ssh_host_key = build(:ssh_host_key, key: 'ssh-whatisthis?! AAAA... foo')
        end

        it 'should not set key_type' do
          expect(@ssh_host_key.key_type).to be_nil
          @ssh_host_key.send(:set_key_type)
          expect(@ssh_host_key.key_type).to be_nil
        end
      end
    end
  end
end
