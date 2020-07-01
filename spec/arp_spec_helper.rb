def create_admin!
  Account.find_by(login: 'admin') || create(:account_admin)
end

def create_user!(opts = {})
  login = opts[:login] || 'user'
  @user = Account.find_by(login: login) || create(:account_user, login: login)

  if opts[:create_service]
    # A regular user should have at least one service
    @user.services << create(:service, description: 'cool stuff') if @user.services.empty?
  end

  @user
end

def login_as_admin!
  login!
  allow(@controller).to receive(:is_arp_admin?)     { true }
  allow(@controller).to receive(:is_arp_sub_admin?) { true }
end

def login_as_user!
  login!('user')
end

# Let's us "login" within a spec.
def login!(user = 'admin', pass = 'mysecret')
  authenticated_user = Account.authenticate(user, pass)
  expect(authenticated_user).to_not be_nil

  @controller.session[:account_id] = authenticated_user.id
  allow(Account).to receive(:find).with(authenticated_user.id) { authenticated_user }
  authenticated_user
end

def login_with_account!(account)
  @controller.session[:account_id] = account.id
  allow(Account).to receive(:find).with(account.id) { account }
end

def mock_login!
  account = mock_model(Account)
  allow(Account).to receive(:authenticate).and_return(account)
  @controller.session[:account_id] = account.id
  allow(Account).to receive(:find).with(account.id) { account }
  account
end

def clear_db!
  CreditCard.delete_all
  BackupQuota.delete_all
  DnsRecord.delete_all
  DnsDomain.delete_all
  BandwidthQuota.delete_all
  VirtualMachine.delete_all
  Vlan.delete_all
  IpBlock.delete_all
  Location.delete_all
  Service.delete_all
  Resource.delete_all
  Account.delete_all
end

RSpec.shared_examples 'Destructive Administrative Action' do
  before do
    # We shouldn't actually hit Yubikey's servers
    allow(Yubikey::OTP::Verify).to receive(:new).and_return(nil)
  end

  describe 'with nil OTP' do
    before do
      @params = { otp: nil }
    end

    it 'should redirect to dashboard' do
      do_post(@params)
      expect(response).to redirect_to(login_accounts_path)
    end

    it 'should set flash error' do
      do_post(@params)
      expect(flash[:error]).to_not be_nil
    end
  end

  describe 'with empty OTP' do
    before do
      @params = { otp: '' }
    end

    it 'should redirect to dashboard' do
      do_post(@params)
      expect(response).to redirect_to(login_accounts_path)
    end

    it 'should set flash error' do
      do_post(@params)
      expect(flash[:error]).to_not be_nil
    end
  end

  describe 'with incorrect identity OTP' do
    before do
      @params = { otp: 'ccffjccjfikrvckthhjnekevccdbtkjibrhgnudkrhev' }
    end

    it 'should redirect to dashboard' do
      do_post(@params)
      expect(response).to redirect_to(login_accounts_path)
    end

    it 'should set flash error' do
      do_post(@params)
      expect(flash[:error]).to_not be_nil
    end
  end

  describe 'with valid OTP' do
    before do
      @params = { otp: 'ccucfccuudvinnftjbjihgefrflbdiffrjthhhbhjlku' }

      otp = double(:otp, valid?: true)
      allow(Yubikey::OTP::Verify).to receive(:new).and_return(otp)
    end

    it 'should not set flash error' do
      do_post(@params)
      expect(flash[:error]).to_not be_nil
    end
  end
end
