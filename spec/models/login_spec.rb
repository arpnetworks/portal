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
        def do_set_credentials
          Login.set_credentials!(@vm, @username, @password, @key)
        end

        context 'with VM' do
          before do
            @vm = create(:virtual_machine)
          end

          it 'should not store password in plain text' do
            Login.delete_all
            do_set_credentials
            logins = Login.all
            expect(logins.size).to eq 1
            expect(logins.first.password).to_not eq @password
          end
        end

        context 'without VM' do
          before do
            @vm = nil
          end

          it 'should do nothing' do
            Login.delete_all
            do_set_credentials
            expect(Login.count).to eq 0
          end
        end
      end

      context 'get_credentials()' do
        def do_get_credentials
          Login.get_credentials(@vm, @key)
        end

        context 'with VM' do
          before do
            @vm = create(:virtual_machine)
          end

          context 'with stored credentials' do
            before do
              Login.delete_all
              Login.set_credentials!(@vm, @username, @password, @key)
            end

            it 'should return username and password' do
              credentials = Login.get_credentials(@vm, @key)
              expect(credentials.size).to eq 1
              cred = credentials.first
              expect(cred.username).to eq @username
              expect(cred.password).to eq @password
            end

            context 'and the wrong key' do
              before do
                @key = "somethin" * 4
              end

              it 'should return a blank password' do
                credentials = Login.get_credentials(@vm, @key)
                expect(credentials.first.password).to eq ""
              end
            end
          end
        end

        context 'without VM' do
          before do
            @vm = nil
          end

          it 'should return empty set' do
            retval = do_get_credentials
            expect(retval).to eq []
          end
        end
      end
    end
  end
end
