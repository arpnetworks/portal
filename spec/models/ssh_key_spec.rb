require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

context SshKey do
  context 'with three SSH keys' do
    before do
      @ssh_key_1 = build(:ssh_key, id: 1, username: 'john', key: 'ssh-rsa AAAA... foo')
      @ssh_key_2 = build(:ssh_key, id: 2, username: 'jane', key: 'ssh-rsa AAAA... bar')
      @ssh_key_3 = build(:ssh_key, id: 3, username: 'fred', key: 'ssh-rsa AAAA... baz')
    end

    describe 'self.to_config_disk_json()' do
      context 'with no keys' do
        it 'should return empty JSON' do
          json = SshKey.to_config_disk_json([])
          json = JSON.parse(json)

          expect(json).to eq({})
        end
      end
      context 'with single key' do
        it 'should return a user with key' do
          allow(SshKey).to receive(:find).with(@ssh_key_1.id).and_return @ssh_key_1
          json = SshKey.to_config_disk_json([{ id: @ssh_key_1.id }])

          expect(json).to eq [{
            name: @ssh_key_1.username,
            ssh_authorized_keys: [
              @ssh_key_1.key
            ]
          }].to_json
        end

        context 'with a user password' do
        end
      end

      context 'with non-existent key' do
        it 'should return empty JSON' do
          allow(SshKey).to receive(:find).and_return nil
          json = SshKey.to_config_disk_json([{ id: 999 }])
          json = JSON.parse(json)

          expect(json).to eq([])
        end
      end

      context 'with multiple keys' do
      end

      context 'with keys with common usernames' do
      end
    end
  end
end
