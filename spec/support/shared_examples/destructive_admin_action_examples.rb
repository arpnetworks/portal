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
      expect(response).to redirect_to(new_account_session_path)
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
      expect(response).to redirect_to(new_account_session_path)
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
      expect(response).to redirect_to(new_account_session_path)
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