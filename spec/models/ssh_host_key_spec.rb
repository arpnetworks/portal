require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

context SshHostKey do
  context 'with an SSH host key' do

    # These are rather 'deep' specs (hardly unit tests), but they are
    # important
    describe 'generate_fingerprints()' do
      context 'with key' do
        before do
        end
      end
      it 'should generate and save SHA256 fingerprint'
      it 'should generate and save MD5 fingerprint'
    end
  end
end
