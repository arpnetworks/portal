require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

context SshHostKey do
  context 'with an SSH host key' do
    # These are rather 'deep' specs (hardly unit tests), but they are
    # important
    describe 'generate_fingerprints()' do
      context 'with key' do
        before do
          @rsa_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCduzEXRrAbTDBRZzoFoktV1wu+CdjAyszKlSzobZfxvdbuuxpdNVEowxbxRDjfEYPrD6amApC3XBaixQnXa5qgDrv8R+g0Qgij1CvuY9jClehU3fC4ZeKhy9qew5sYJtS9uAwha1bip38j5C21vDQ9R1mrDdjUwvb9rXBBOARoPvlS6t48jcnnWoawvbmsYiNG1GG3uqRdHEh91nUYsWrS6cY38ecuDgbPjb36FtYeJdpQ9WmljwiD1tQtCqPIzHWqOpEpQY1O37/xMHJa6E4ANZeZvJdv5H75+egw/omO4EDCNWO4/pYVSLjJ8stsjPZq2dBpaQmA+NYsVkVKHeToN/l8/UuwKD1lJO9HglwnTgpjnadO/8XmY+ITsxBBL1gTd6NVH0ZU/tLterNgB9XU89rxhFdaaDl4x6UsJvjFYdzFDVCyycMyOOgwgW+0ZQ0oQcsrb9VNE3R/0BbyjGjNO8IGXD8hiSzUq43TZiJlxhAHqQOM4LsGcpCqfABo7Rc= foo'
        end

        it 'should generate and save SHA256 fingerprint' do
          @ssh_host_key = build(:ssh_host_key, key: @rsa_key)
          @ssh_host_key.send(:generate_fingerprints)

          expect(@ssh_host_key.fingerprint_sha256).to include('SHA256:l29Gm4WNrcMHoIJYaz0SDLSUSt+4bGBTZmdzw7vI6a8')
        end

        it 'should generate and save MD5 fingerprint' do
          @ssh_host_key = build(:ssh_host_key, key: @rsa_key)
          @ssh_host_key.send(:generate_fingerprints)

          expect(@ssh_host_key.fingerprint_md5).to include('MD5:0a:ea:3e:a8:c5:bd:20:5b:a1:a8:e8:6f:b4:e5:b4:fa')

        end
      end
    end
  end
end
