require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

context Login do
  context 'with a username and password pair' do
    before do
      @username = 'john'
      @password = 'pwnme'
    end

    context 'with symmetric key' do
      before do
        @key = Account.generate_derived_key('myloginpassword', 'mysalt')
      end

      context 'set_credentials!()' do
        context 'with VM' do
        end

        context 'without VM' do
          it 'should do nothing'
        end
      end

      context 'get_credentials()' do
      end
    end
  end
end
