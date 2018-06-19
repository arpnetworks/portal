require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')


context ServicesController do

  before(:context) do
    create_user!
  end

  before do
    @account = login_as_user!
  end

  specify "should be a ServicesController" do
    expect(controller).to be_an_instance_of(ServicesController)
  end

  context "index action" do
    specify "should respond with success" do
      get :index, :account_id => @account.id
      expect(@response).to be_success
    end
  end

  context "show action" do
    before do
      @service = @account.services.first
    end

    specify "should respond with success" do
      get :show, :account_id => @account.id, :id => @service.id
      expect(@response).to be_success
      expect(@response).to render_template('show')
    end

    specify "should redirect to index when given bad id" do
      get :show, :account_id => @account.id, :id => 999
      expect(@response).to redirect_to(account_services_path(@account.id))
      expect(flash[:error]).to_not be_nil
    end

    specify "should create a @services array with just this service" do
      get :show, :account_id => @account.id, :id => @service.id
      expect(assigns(:services).size).to eq 1
      expect(assigns(:services)).to eq [@service]
    end

    specify "should set @description from @service.description" do
      get :show, :account_id => @account.id, :id => @service.id
      expect(assigns(:description)).to eq @service.description
    end

    specify "should not show deleted record" do
      @service = create :service, :deleted
      @account.services << @service

      get :show, :account_id => @account.id, :id => @service.id
      expect(assigns(:service)).to be_nil
    end

    context "resource details" do
      specify "should set @virtual_machines" do
        get :show, :account_id => @account.id, :id => @service.id
        expect(assigns(:resources)).to eq @service.resources
      end
    end
  end

  context "update label action" do
    def do_put(opts = {})
      put :update_label, { :account_id => @account.id, :id => @service.id }.merge(opts)
    end

    before do
      @service = @account.services.first
    end

    specify "should update the label of service" do
      label = 'foo'
      expect(@service.label).to_not eq label
      do_put(:service => { :label => label })

      expect(response).to redirect_to(account_service_path(@account.id, @service.id))

      @reloaded_service = Service.find(@service.id)
      expect(@reloaded_service.label).to eq label

      expect(flash[:notice]).to_not be_empty
    end
  end
end
