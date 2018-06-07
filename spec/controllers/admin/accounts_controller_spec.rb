require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../my_spec_helper'

describe Admin::AccountsController do
  fixtures :accounts

  before do
    login!
    @account = accounts(:user_1)
    @account_params = { :login => 'login', :email => 'foobar@example.com' }
    @params  = { :id => @account.id, :account => @account_params }

    controller.stub!(:is_arp_admin?).and_return(true)
    controller.stub!(:is_arp_sub_admin?).and_return(true)
    controller.stub!(:set_admin_state).and_return(true)
    controller.stub!(:login_required)
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
      assigns(:account).should be_new_record
      response.should be_success
    end

    it "should set @include_blank" do
      do_get
      assigns(:include_blank).should be_true
    end
  end

  describe "handling POST /admin/accounts" do
    def do_post(opts = {})
      post :create, opts
    end

    it "should create new account" do
      num_records = Account.count
      do_post(@params.merge(:account => @params[:account].merge(:login => 'foo2', :company => 'foo', :password => 'foo', :password_confirmation => 'foo')))
      Account.count.should == num_records + 1
      response.should redirect_to(admin_accounts_path)
      flash[:notice].should_not be_nil
    end

    it "should go back to new page if error creating" do
      do_post(@params.merge(:account => { :login => '' })) # Blank login
      response.should render_template('admin/accounts/new')
      assigns(:include_blank).should == true
    end
  end

  describe "handling GET /admin/accounts" do
    it "should display a list of accounts" do
      do_get
      assigns(:accounts).should_not be_empty
      response.should be_success
    end
  end

  describe "handling GET /admin/accounts/1" do
    def do_get(opts = {})
      get :show, opts
    end

    it "should show the account" do
      do_get @params
      response.should be_success
      response.should render_template('admin/accounts/show')
      assigns(:account).id.should == @account.id
    end

    it "should redirect when the account is not found" do
      do_get @params.merge(:id => 999)
      flash[:error].should_not be_nil
      response.should redirect_to(admin_accounts_path)
    end
  end

  describe "handling GET /admin/accounts/1/edit" do
    def do_get(opts = {})
      get :edit, opts
    end

    it "should show the account" do
      do_get @params
      response.should be_success
      assigns(:account).id.should == @account.id
    end

    it "should redirect when the account is not found" do
      do_get @params.merge(:id => 999)
      flash[:error].should_not be_nil
      response.should redirect_to(admin_accounts_path)
    end
  end

  describe "handling PUT /admin/accounts/1" do
    def do_put(opts = {})
      put :update, opts
    end

    def do_mock(opts = {})
      @account = mock_model(Account, {}.merge(opts))
      Account.should_receive(:find).with(@account.id.to_s).and_return(@account)
      @account.should_receive(:login=)
    end

    it "should update the account" do
      @new_account = { :company => 'a new company' }
      @account.company.should_not == @new_account[:company]
      do_put(@params.merge(:account => @params[:account].merge(@new_account)))
      response.should redirect_to(last_location)
      flash[:notice].should_not be_empty
      @reloaded_account = Account.find(@account.id)
      @reloaded_account.company.should == @new_account[:company]
    end

    it "should go back to edit page if error updating" do
      # Using mocks/stubs here
      do_mock(:update_attributes => false)

      do_put(@params.merge(:id => @account.id))
      response.should render_template('admin/accounts/edit')
    end

    it "should redirect when the account is not found" do
      do_put @params.merge(:id => 999)
      flash[:error].should_not be_nil
      response.should redirect_to(admin_accounts_path)
    end

    it "should not update password if one is not supplied" do
      do_mock

      @account.should_receive(:update_attributes).with(@account_params.stringify_keys!)

      do_put(@params.merge(:id => @account.id, :account => @account_params.merge(
                           :password => '', :password_confirmation => '')))
    end
  end

  def mock_account(stubs={})
    @mock_account ||= mock_model(Account, stubs)
  end

  describe "responding to DELETE destroy" do
    it "should destroy the requested accounts" do
      Account.should_receive(:find).with("37").and_return(mock_account)
      mock_account.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the location that brought us here" do
      Account.stub!(:find).and_return(mock_account(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(last_location)
    end

    it "should set flash[:error] if destroy() raises AR exception" do
      bad_monkey = mock(Account)
      bad_monkey.should_receive(:destroy).and_raise(ActiveRecord::StatementInvalid)
      Account.stub!(:find).and_return(bad_monkey)
      delete :destroy, :id => "1"
      flash[:error].should_not be_nil
    end
  end
end
