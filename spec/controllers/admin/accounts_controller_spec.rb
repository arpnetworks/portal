require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::AccountsController do

  before(:context) do
    create_admin!
  end

  before do
    login_as_admin!

    @account = stub_model(Account, login: 'login', email: 'foo@example.com')
    @account_params = { login: @account.login, email: @account.email }
    @params  = { id: @account.id, account: @account_params }

    allow(controller).to receive(:is_arp_admin?)     { true }
    allow(controller).to receive(:is_arp_sub_admin?) { true }
    allow(controller).to receive(:set_admin_state)   { true }
    allow(controller).to receive(:login_required)
    allow(controller).to receive(:last_location)     { '/foo' }
  end

  def do_get(opts = {})
    get :index, opts
  end

  describe "handling GET /admin/accounts/new" do
    def do_get(opts = {})
      get :new, opts
    end

    it "should display new account form" do
      do_get
      expect(assigns(:account)).to be_new_record
      expect(response).to be_success
    end

    it "should set @include_blank" do
      do_get
      expect(assigns(:include_blank)).to be true
    end
  end

  describe "handling POST /admin/accounts" do
    def do_post(opts = {})
      post :create, opts
    end

    it "should create new account" do
      num_records = Account.count
      do_post(@params.merge(:account => @params[:account].merge(:login => 'foo2', :company => 'foo', :password => 'foo', :password_confirmation => 'foo')))
      expect(Account.count).to eq(num_records + 1)
      expect(response).to redirect_to(admin_accounts_path)
      expect(flash[:notice]).to_not be_nil
    end

    it "should go back to new page if error creating" do
      do_post(@params.merge(:account => { :login => '' })) # Blank login
      expect(response).to render_template('admin/accounts/new')
      expect(assigns(:include_blank)).to be true
    end
  end

  describe "handling GET /admin/accounts" do
    it "should display a list of accounts" do
      do_get
      expect(assigns(:accounts)).to_not be_empty
      expect(response).to be_success
    end
  end

  describe "handling GET /admin/accounts/1" do
    def do_get(opts = {})
      get :show, opts
    end

    it "should show the account" do
      allow(Account).to receive(:find) { @account }
      do_get @params
      expect(response).to be_success
      expect(response).to render_template('admin/accounts/show')
      expect(assigns(:account).id).to eq @account.id
    end

    it "should redirect when the account is not found" do
      allow(Account).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_accounts_path)
    end
  end

  describe "handling GET /admin/accounts/1/edit" do
    def do_get(opts = {})
      get :edit, opts
    end

    it "should show the account" do
      allow(Account).to receive(:find) { @account }
      do_get @params
      expect(response).to be_success
      expect(assigns(:account).id).to eq @account.id
    end

    it "should redirect when the account is not found" do
      allow(Account).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_accounts_path)
    end
  end

  describe "handling PUT /admin/accounts/1" do
    def do_put(opts = {})
      put :update, opts
    end

    it "should go back to edit page if error updating" do
      allow(Account).to receive(:find) { @account }
      allow(@account).to receive(:update_attributes).and_raise(ActiveRecord::StatementInvalid, 'foo')
      do_put(@params.merge(:id => @account.id))
      expect(response).to render_template('admin/accounts/edit')
    end

    it "should redirect when the account is not found" do
      do_put @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_accounts_path)
    end

    it "should not update password if one is not supplied" do
      allow(Account).to receive(:find) { @account }
      expect(@account).to receive(:update_attributes).with(@account_params.stringify_keys!)

      do_put(@params.merge(:id => @account.id, :account => @account_params.merge(
                           :password => '', :password_confirmation => '')))
    end
  end

  def mock_account(stubs={})
    @mock_account ||= mock_model(Account, stubs)
  end

  describe "responding to DELETE destroy" do
    it "should destroy the requested accounts" do
      allow(controller).to receive(:last_location) { '/foo' }
      expect(Account).to receive(:find).with("37") { mock_account }
      expect(mock_account).to receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "should redirect to the location that brought us here" do
      allow(controller).to receive(:last_location) { '/foo' }
      allow(Account).to receive(:find) { mock_account(destroy: true) }
      delete :destroy, :id => "1"
      expect(response).to redirect_to('/foo')
    end

    it "should set flash[:error] if destroy() raises AR exception" do
      bad_monkey = double(Account)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'foo')
      allow(Account).to receive(:find) { bad_monkey }
      delete :destroy, :id => "1"
      expect(flash[:error]).to_not be_nil
    end
  end
end
