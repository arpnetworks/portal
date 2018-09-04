require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::VlansController do

  before(:context) do
    create_admin!
  end

  before do
    login_as_admin!
    @p = { 'vlan': '999', 'label': 'ACME Inc' }
  end

  def mock_vlan(stubs={})
    @mock_vlan ||= mock_model(Vlan, stubs)
  end

  describe "responding to GET index" do

    it "should expose all admin_vlans as @admin_vlans" do
      vlans = double("All VLANs")
      expect(Vlan).to receive(:all) { vlans }
      expect(vlans).to receive(:order) { [mock_vlan] }
      expect(mock_vlan).to receive(:vlan).at_least(:once)

      get :index
      expect(assigns[:vlans]).to eq([mock_vlan])
    end

  end

  describe "responding to GET show" do

    it "should expose the requested vlans as @vlans" do
      expect(Vlan).to receive(:find).with("37") { mock_vlan }
      get :show, :id => "37"
      expect(assigns[:vlan]).to eq(mock_vlan)
    end

    describe "with mime type of xml" do

      it "should render the requested vlans as xml" do
        xml = "generated XML"
        request.env["HTTP_ACCEPT"] = "application/xml"
        expect(Vlan).to receive(:find).with("37") { mock_vlan }
        expect(mock_vlan).to receive(:to_xml) { xml }
        get :show, :id => "37"
        expect(response.body).to eq(xml)
      end

    end

  end

  describe "responding to GET new" do

    it "should expose a new vlans as @vlans" do
      expect(Vlan).to receive(:new) { mock_vlan }
      get :new
      expect(assigns[:vlan]).to eq(mock_vlan)
    end

  end

  describe "responding to GET edit" do

    it "should expose the requested vlans as @vlans" do
      expect(Vlan).to receive(:find).with("37") { mock_vlan }
      get :edit, :id => "37"
      expect(assigns[:vlan]).to eq(mock_vlan)
    end

  end

  describe "responding to POST create" do

    def do_create
      post :create, vlan: @p
    end

    describe "with valid params" do

      it "should expose a newly created vlans as @vlans" do
        expect(Vlan).to receive(:new).with(@p) { mock_vlan(save: true) }
        do_create
        expect(assigns(:vlan)).to eq(mock_vlan)
      end

      it "should redirect to all service codes" do
        allow(Vlan).to receive(:new) { mock_vlan(save: true) }
        do_create
        expect(response).to redirect_to(admin_vlans_path)
      end

    end

    describe "with invalid params" do

      it "should expose a newly created but unsaved vlans as @vlans" do
        allow(Vlan).to receive(:new).with(@p) { mock_vlan(save: false) }
        do_create
        expect(assigns(:vlan)).to eq(mock_vlan)
      end

      it "should re-render the 'new' template" do
        allow(Vlan).to receive(:new) { mock_vlan(save: false) }
        do_create
        expect(response).to render_template('new')
      end

    end

  end

  describe "responding to PUT udpate" do

    def do_update(id = "37")
      patch :update, id: id, vlan: @p
    end

    describe "with valid params" do

      it "should update the requested vlans" do
        expect(Vlan).to receive(:find).with("37") { mock_vlan }
        expect(mock_vlan).to receive(:update_attributes).with(@p)
        do_update
      end

      it "should expose the requested vlans as @vlans" do
        allow(Vlan).to receive(:find) { mock_vlan(update_attributes: true) }
        do_update("1")
        expect(assigns(:vlan)).to eq(mock_vlan)
      end

      it "should redirect to all service codes" do
        allow(Vlan).to receive(:find) { mock_vlan(update_attributes: true) }
        do_update("1")
        expect(response).to redirect_to(admin_vlans_path)
      end

    end

    describe "with invalid params" do

      it "should update the requested vlans" do
        expect(Vlan).to receive(:find).with("37") { mock_vlan }
        expect(mock_vlan).to receive(:update_attributes).with(@p)
        do_update
      end

      it "should expose the vlans as @vlans" do
        allow(Vlan).to receive(:find) { mock_vlan(update_attributes: false) }
        do_update("1")
        expect(assigns(:vlan)).to eq(mock_vlan)
      end

      it "should re-render the 'edit' template" do
        allow(Vlan).to receive(:find) { mock_vlan(update_attributes: false) }
        do_update("1")
        expect(response).to render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    def do_destroy(id = '37')
      delete :destroy, id: id
    end

    it "should destroy the requested vlans" do
      expect(Vlan).to receive(:find).with("37") { mock_vlan }
      expect(mock_vlan).to receive(:destroy)
      do_destroy
    end

    it "should redirect to the admin_vlans list" do
      allow(Vlan).to receive(:find) { mock_vlan(destroy: true) }
      do_destroy("1")
      expect(response).to redirect_to(admin_vlans_url)
    end

    it "should set flash[:error] if destroy() raises AR exception" do
      bad_monkey = double(Vlan)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'uhoh')
      allow(Vlan).to receive(:find) { bad_monkey }
      do_destroy("1")
      expect(flash[:error]).to_not be_nil
    end

  end

  describe "responding to POST shutdown" do
    it_should_behave_like "Destructive Administrative Action"

    before do
      @id = "1"
      @virtual_machine_id = 1
      @otp = 'foo'
      @location = 'lax'

      allow(@controller).to receive(:send_command)
    end

    def do_post(opts = {})
      post :shutdown, { id: @id,
                        virtual_machine_id: @virtual_machine_id,
                        otp2: @otp,
                        location: @location }.merge(opts)
    end

    describe "with valid OTP" do
      before do
        allow(@controller).to receive(:verify_otp) { true }
      end

      it "should redirect to virtual machine details page" do
        allow(Vlan).to receive(:mark_shutdown!)
        do_post
        expect(response).to redirect_to(admin_virtual_machine_path(@virtual_machine_id))
      end

      it "should issue command for VLAN shutdown" do
        allow(Vlan).to receive(:mark_shutdown!)
        expect(@controller).to receive(:send_command).with('shutdown_vlan', @id, @location, @otp)
        do_post
      end

      it "should mark VLAN as shutdown in account" do
        account = mock_model(Account)
        expect(account).to receive(:suspend!)

        virtual_machine = mock_model(VirtualMachine, account: account)
        expect(VirtualMachine).to receive(:find).with(@virtual_machine_id.to_s)\
          { virtual_machine }

        do_post
      end
    end
  end

  describe "responding to POST restore" do
    it_should_behave_like "Destructive Administrative Action"

    before do
      @id = "1"
      @virtual_machine_id = 1
      @otp = 'foo'
      @location = 'lax'

      allow(@controller).to receive(:send_command)
    end

    def do_post(opts = {})
      post :restore, { id: @id,
                       virtual_machine_id: @virtual_machine_id,
                       otp2: @otp,
                       location: @location }.merge(opts)
    end

    describe "with valid OTP" do
      before do
        allow(@controller).to receive(:verify_otp) { true }
      end

      it "should redirect to virtual machine details page" do
        allow(Vlan).to receive(:mark_shutdown!)
        do_post
        expect(response).to redirect_to(admin_virtual_machine_path(@virtual_machine_id))
      end

      it "should issue command for VLAN restoration" do
        allow(Vlan).to receive(:mark_shutdown!)
        expect(@controller).to receive(:send_command).with('restore_vlan', @id, @location, @otp)
        do_post
      end

      it "should mark VLAN as not shutdown in account" do
        account = mock_model(Account)
        expect(account).to receive(:unsuspend!)

        virtual_machine = mock_model(VirtualMachine, account: account)
        expect(VirtualMachine).to receive(:find).with(@virtual_machine_id.to_s) { virtual_machine }

        do_post
      end
    end
  end

  describe "send_command()" do
    before do
      @vlan_id = '1999'
      @otp = 'foo'
      @location = 'lax'

      # We don't want SSH to actually execute
      allow(Kernel).to receive(:system)
    end

    def do_send_command(cmd, vlan_id, location, otp)
      Admin::VlansController.new.instance_eval do
        send_command(cmd, vlan_id, location, otp)
      end
    end

    specify "should execute shell command to shutdown VLAN" do
      expect(Kernel).to receive(:system).\
        with("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$HOST_RANCID_USER}@#{$HOST_RANCID}", @otp, 'shutdown_vlan', @vlan_id.to_s, @location)

      do_send_command('shutdown_vlan', @vlan_id, @location, @otp)
    end

    specify "should execute shell command to restore VLAN" do
      expect(Kernel).to receive(:system).\
        with("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$HOST_RANCID_USER}@#{$HOST_RANCID}", @otp, 'restore_vlan', @vlan_id.to_s, @location)

      do_send_command('restore_vlan', @vlan_id, @location, @otp)
    end
  end
end
