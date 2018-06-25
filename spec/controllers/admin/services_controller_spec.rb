require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::ServicesController do

  before(:context) do
    create_admin!
  end

  before do
    login_as_admin!

    # @account = stub_model(Account, login: 'login', email: 'foo@example.com')
    # @account_params = { login: @account.login, email: @account.email }
    # @params  = { id: @account.id, account: @account_params }

    @service = create :service
    @params  = { :id => @service.id }

    allow(controller).to receive(:is_arp_admin?)     { true }
    allow(controller).to receive(:is_arp_sub_admin?) { true }
    allow(controller).to receive(:set_admin_state)   { true }
    allow(controller).to receive(:login_required)

    @last_location = '/foo'
    allow(controller).to receive(:last_location)     { @last_location }
  end

  def do_get(opts = {})
    get :index, opts
  end

  describe "handling GET /admin/services/new" do
    def do_get(opts = {})
      get :new, opts
    end

    it "should display new service form" do
      do_get
      expect(assigns(:service)).to be_new_record
      expect(response).to be_success
    end

    it "should set @include_blank" do
      do_get
      expect(assigns(:include_blank)).to be true
    end
  end

  describe "handling POST /admin/services" do
    def do_post(opts = {})
      post :create, opts
    end

    it "should create new service" do
      num_records = Service.count
      do_post(@params.merge(:service => { :account_id => 1, :title => 'foo' }))
      expect(Service.count).to eq (num_records + 1)
      expect(response).to redirect_to(admin_services_path)
      expect(flash[:notice]).to_not be_nil
    end

    it "should go back to new page if error creating" do
      do_post(@params.merge(:service => { :title => 'foo' })) # No account
      expect(response).to render_template('admin/services/new')
      expect(assigns(:include_blank)).to eq true
    end
  end

  describe "handling GET /admin/services" do
    it "should display a list of services" do
      do_get
      expect(assigns(:services)).to_not be_empty
      expect(response).to be_success
    end
  end

  describe "handling GET /admin/services/1" do
    def do_get(opts = {})
      get :show, opts
    end

    it "should show the service" do
      do_get @params
      expect(response).to be_success
      expect(response).to render_template('services/show')
      expect(assigns(:service).id).to eq @service.id
    end

    it "should redirect when the service is not found" do
      do_get @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_services_path)
    end
  end

  describe "handling GET /admin/services/1/edit" do
    def do_get(opts = {})
      get :edit, opts
    end

    it "should show the service" do
      do_get @params
      expect(response).to be_success
      expect(assigns(:service).id).to eq @service.id
    end

    it "should redirect when the service is not found" do
      do_get @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_services_path)
    end
  end

  describe "handling PUT /admin/services/1/edit" do
    def do_put(opts = {})
      put :update, opts
    end

    it "should update the service" do
      @new_service = { :title => 'a new title' }
      expect(@service.title).to_not eq @new_service[:title]
      do_put(@params.merge(:service => @new_service))
      expect(response).to redirect_to(@last_location)
      expect(flash[:notice]).to_not be_empty
      @reloaded_service = Service.find(@service.id)
      expect(@reloaded_service.title).to eq @new_service[:title]
    end

    it "should go back to edit page if error updating" do
      # Using mocks/stubs here
      @service = mock_model(Service, :update_attributes => false)
      expect(Service).to receive(:find).with(@service.id.to_s).and_return(@service)

      do_put(@params.merge(:id => @service.id, service: { title: 'foo' }))
      expect(response).to render_template('admin/services/edit')
    end

    it "should redirect when the service is not found" do
      do_put @params.merge(:id => 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_services_path)
    end
  end

  def mock_service(stubs={})
    @mock_service ||= mock_model(Service, stubs)
  end

  describe "responding to DELETE destroy" do
    it "should destroy the requested services" do
      expect(Service).to receive(:find).with("37").and_return(mock_service)
      expect(mock_service).to receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "should redirect to the location that brought us here" do
      allow(Service).to receive(:find).and_return(mock_service(destroy: true))
      delete :destroy, :id => "1"
      expect(response).to redirect_to(@last_location)
    end

    it "should set flash[:error] if destroy() raises AR exception" do
      bad_monkey = mock_model(Service)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'bad')
      allow(Service).to receive(:find).and_return(bad_monkey)
      delete :destroy, :id => "1"
      expect(flash[:error]).to_not be_nil
    end
  end
end
