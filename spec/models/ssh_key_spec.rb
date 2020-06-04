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
        before do
          allow(SshKey).to receive(:find).with(@ssh_key_1.id).and_return @ssh_key_1
        end

        it 'should return a user with key' do
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
        before do
          allow(SshKey).to receive(:find).with(@ssh_key_1.id).and_return @ssh_key_1
          allow(SshKey).to receive(:find).with(@ssh_key_2.id).and_return @ssh_key_2
          allow(SshKey).to receive(:find).with(@ssh_key_3.id).and_return @ssh_key_3
        end

        it 'should return users with multiple keys' do
          json = SshKey.to_config_disk_json([
                                              { id: @ssh_key_1.id },
                                              { id: @ssh_key_2.id },
                                              { id: @ssh_key_3.id }
                                            ])

          expect(json).to eq [
            {
              name: @ssh_key_1.username,
              ssh_authorized_keys: [
                @ssh_key_1.key
              ]
            },
            {
              name: @ssh_key_2.username,
              ssh_authorized_keys: [
                @ssh_key_2.key
              ]

            },
            {
              name: @ssh_key_3.username,
              ssh_authorized_keys: [
                @ssh_key_3.key
              ]

            }
          ].to_json
        end
      end

      context 'with keys with common usernames' do
        before do
          @ssh_key_1 = build(:ssh_key, id: 1, username: 'john', key: 'ssh-rsa AAAA... foo')
          @ssh_key_2 = build(:ssh_key, id: 2, username: 'jane', key: 'ssh-rsa AAAA... bar')
          @ssh_key_3 = build(:ssh_key, id: 3, username: 'john', key: 'ssh-rsa AAAA... baz')

          allow(SshKey).to receive(:find).with(@ssh_key_1.id).and_return @ssh_key_1
          allow(SshKey).to receive(:find).with(@ssh_key_2.id).and_return @ssh_key_2
          allow(SshKey).to receive(:find).with(@ssh_key_3.id).and_return @ssh_key_3
        end

        it 'should return users with keys grouped by common username' do
          json = SshKey.to_config_disk_json([
                                              { id: @ssh_key_1.id },
                                              { id: @ssh_key_2.id },
                                              { id: @ssh_key_3.id }
                                            ])
          expect(json).to eq [
            {
              name: @ssh_key_1.username,
              ssh_authorized_keys: [
                @ssh_key_1.key,
                @ssh_key_3.key
              ]
            },
            {
              name: @ssh_key_2.username,
              ssh_authorized_keys: [
                @ssh_key_2.key
              ]

            }
          ].to_json
        end
      end
    end
  end
end
