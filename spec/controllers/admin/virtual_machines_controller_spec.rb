require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::VirtualMachinesController do
  before(:context) do
    create_admin!
  end

  before do
    @account = login_as_admin!

    @virtual_machine = create :virtual_machine
    @params = { id: @virtual_machine.id }

    allow(controller).to receive(:is_arp_admin?)     { true }
    allow(controller).to receive(:is_arp_sub_admin?) { true }
    allow(controller).to receive(:set_admin_state)   { true }
    allow(controller).to receive(:login_required)

    @last_location = '/foo'
    allow(controller).to receive(:last_location) { @last_location }
  end

  def do_get(opts = {})
    get :index, params: opts
  end

  describe 'handling GET /admin/virtual_machines/new' do
    def do_get(opts = {})
      get :new, params: opts
    end

    it 'should display new virtual_machine form' do
      do_get
      expect(assigns(:virtual_machine)).to be_new_record
      expect(response).to be_success
    end

    it 'should set @include_blank' do
      do_get
      expect(assigns(:include_blank)).to be true
    end

    it 'should auto-generate a UUID' do
      do_get
      expect(assigns(:virtual_machine).uuid).to_not be_nil
    end
  end

  describe 'handling POST /admin/virtual_machines' do
    def do_post(opts = {})
      post :create, params: opts
    end

    it 'should create new virtual_machine' do
      num_records = VirtualMachine.count
      do_post(@params.merge(virtual_machine: { notes: 'foo',
                                               uuid: 'lsk',
                                               host: 'foo.example.com',
                                               ram: 1024,
                                               storage: 20,
                                               label: 'foo' }))
      expect(VirtualMachine.count).to eq(num_records + 1)
      expect(response).to redirect_to(admin_virtual_machines_path)
      expect(flash[:notice]).to_not be_nil
    end

    it 'should go back to new page if error creating' do
      expect(VirtualMachine).to receive(:new).and_return(mock_model(VirtualMachine, save: false))
      do_post(@params.merge(virtual_machine: { notes: 'foo' }))
      expect(response).to render_template('admin/virtual_machines/new')
      expect(assigns(:include_blank)).to be true
    end
  end

  describe 'handling GET /admin/virtual_machines' do
    it 'should display a list of virtual machines' do
      do_get
      expect(assigns(:virtual_machines)).to_not be_empty
      expect(response).to be_success
      expect(response).to render_template('index')
    end
  end

  describe 'handling GET /admin/virtual_machines/1' do
    def do_get(opts = {})
      get :show, params: opts
    end

    it 'should show the virtual_machine' do
      do_get @params
      expect(response).to be_success
      expect(response).to render_template('virtual_machines/show')
      expect(assigns(:virtual_machine).id).to eq @virtual_machine.id
    end

    it 'should show the virtual_machine when provided UUID' do
      do_get @params.merge(id: @virtual_machine.uuid)
      expect(response).to be_success
      expect(response).to render_template('virtual_machines/show')
      expect(assigns(:virtual_machine).id).to eq @virtual_machine.id
      expect(assigns(:virtual_machine).uuid).to eq @virtual_machine.uuid
    end

    it 'should redirect when the virtual_machine is not found' do
      do_get @params.merge(id: 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_virtual_machines_path)
    end
  end

  describe 'handling GET /admin/virtual_machines/1/edit' do
    def do_get(opts = {})
      get :edit, params: opts
    end

    it 'should show the virtual_machine' do
      do_get @params
      expect(response).to be_success
      expect(assigns(:virtual_machine).id).to eq @virtual_machine.id
    end

    it 'should redirect when the virtual_machine is not found' do
      do_get @params.merge(id: 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_virtual_machines_path)
    end

    it 'should set @include_blank' do
      do_get @params
      expect(assigns(:include_blank)).to be true
    end
  end

  describe 'handling PUT /admin/virtual_machines/1/edit' do
    def do_put(opts = {})
      put :update, params: opts
    end

    it 'should update the virtual_machine' do
      @new_virtual_machine = { notes: 'a new notes' }
      expect(@virtual_machine.notes).to_not eq @new_virtual_machine[:notes]
      do_put(@params.merge(virtual_machine: @new_virtual_machine))
      expect(response).to redirect_to(@last_location)
      expect(flash[:notice]).to_not be_empty
      @reloaded_virtual_machine = VirtualMachine.find(@virtual_machine.id)
      expect(@reloaded_virtual_machine.notes).to eq @new_virtual_machine[:notes]
    end

    it 'should go back to edit page if error updating' do
      # Using mocks/stubs here
      @virtual_machine = mock_model(VirtualMachine, update: false)
      expect(VirtualMachine).to receive(:find).with(@virtual_machine.id.to_s).and_return(@virtual_machine)
      allow(@virtual_machine).to receive(:virtual_machines_interfaces).and_return([:interfaces])

      do_put(@params.merge(id: @virtual_machine.id, virtual_machine: { notes: 'foo' }))
      expect(response).to render_template('admin/virtual_machines/edit')
    end

    it 'should redirect when the virtual_machine is not found' do
      do_put @params.merge(id: 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_virtual_machines_path)
    end
  end

  def mock_virtual_machine(stubs = {})
    @mock_virtual_machine ||= mock_model(VirtualMachine, stubs)
  end

  describe 'responding to DELETE destroy' do
    it 'should destroy the requested virtual_machines' do
      expect(VirtualMachine).to receive(:find).with('37').and_return(mock_virtual_machine)
      expect(mock_virtual_machine).to receive(:destroy)
      delete :destroy, params: { id: '37' }
    end

    it 'should redirect to the location that brought us here' do
      allow(VirtualMachine).to receive(:find).and_return(mock_virtual_machine(destroy: true))
      delete :destroy, params: { id: '1' }
      expect(response).to redirect_to(@last_location)
    end

    it 'should set flash[:error] if destroy() raises AR exception' do
      bad_monkey = mock_model(VirtualMachine)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'bad')
      allow(VirtualMachine).to receive(:find).and_return(bad_monkey)
      delete :destroy, params: { id: '1' }
      expect(flash[:error]).to_not be_nil
    end
  end
end
