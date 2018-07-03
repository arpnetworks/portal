require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

context VirtualMachinesController do

  before(:context) do
    create_user!
  end

  before do
    @account = login_as_user!
    @vm = create :virtual_machine
    @service = @vm.resource.service

    @account.services << @service

    allow(ARP_REDIS).to receive(:lpush) { nil }
  end

  context "boot action" do

    def do_get(opts = {})
      get :boot, { :account_id => @account.id, :service_id => @service.id,
                   :id => @vm.id }.merge(opts)
    end

    context "with valid VM" do

      specify "should set flash notice" do
        do_get
        expect(flash[:notice_for_vm]).to_not be_nil
      end

      specify "should redirect to service page" do
        do_get
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                              @service.id))
      end

      specify "should redirect to admin VM page if coming from admin" do
        @request.env['HTTP_REFERER'] = \
          "http://localhost:3000/admin/virtual_machines/#{@vm.id}"
        do_get
        expect(@response).to redirect_to(admin_virtual_machine_path(@vm.id))
      end

      specify "should write request to 'start' VM" do
        allow(@account).to receive("find_virtual_machine_by_id").with(@vm.id.to_s) { @vm }
        expect(@vm).to receive(:change_state!).with('start')
        do_get
      end
    end

    context "with invalid VM" do

      specify "should not set flash notice" do
        do_get(:id => 999)
        expect(flash[:notice_for_vm]).to be_nil
      end

      specify "should redirect to service page" do
        do_get(:id => 999)
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                              @service.id))
      end
    end
  end

  context "shutdown action" do

    def do_get(opts = {})
      get :shutdown, { :account_id => @account.id, :service_id => @service.id,
                       :id => @vm.id }.merge(opts)
    end

    context "with valid VM" do

      specify "should set flash notice" do
        do_get
        expect(flash[:notice_for_vm]).to_not be_nil
      end

      specify "should redirect to service page" do
        do_get
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                          @service.id))
      end

      specify "should write request to 'shutdown' VM" do
        allow(@account).to receive("find_virtual_machine_by_id").with(@vm.id.to_s) { @vm }
        expect(@vm).to receive(:change_state!).with('shutdown')
        do_get
      end
    end

    context "with invalid VM" do

      specify "should not set flash notice" do
        do_get(:id => 999)
        expect(flash[:notice_for_vm]).to be_nil
      end

      specify "should redirect to service page" do
        do_get(:id => 999)
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                          @service.id))
      end
    end
  end

  context "shutdown_hard action" do

    def do_get(opts = {})
      get :shutdown_hard, { :account_id => @account.id, :service_id => @service.id,
                            :id => @vm.id }.merge(opts)
    end

    context "with valid VM" do

      specify "should set flash notice" do
        do_get
        expect(flash[:notice_for_vm]).to_not be_nil
      end

      specify "should redirect to service page" do
        do_get
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                          @service.id))
      end

      specify "should write request to 'destroy' VM" do
        allow(@account).to receive("find_virtual_machine_by_id").with(@vm.id.to_s) { @vm }
        expect(@vm).to receive(:change_state!).with('destroy')
        do_get
      end
    end

    context "with invalid VM" do

      specify "should not set flash notice" do
        do_get(:id => 999)
        expect(flash[:notice_for_vm]).to be_nil
      end

      specify "should redirect to service page" do
        do_get(:id => 999)
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                          @service.id))
      end
    end
  end

  context "iso_change" do

    before do
      @iso_files = [
        'OpenBSD-5.4-amd64-install54.iso',
        'FreeBSD-9.2-RELEASE-i386-disc1.iso'
      ]

      allow(@account).to receive(:find_virtual_machine_by_id).with(@vm.id.to_s).and_return(@vm)
      allow(controller).to receive(:iso_files).and_return(@iso_files)
      allow(@vm).to receive(:set_iso!)
    end

    def do_get(opts = {})
      get :iso_change, { :account_id => @account.id,
                         :service_id => @service.id,
                         :iso_file   => @iso_files[0],
                         :id => @vm.id }.merge(opts)
    end

    context "with valid VM" do

      context "with valid ISO filename" do
        specify "should set flash notice" do
          do_get
          expect(flash[:notice_for_vm_iso]).to_not be_nil
        end

        specify "should redirect to service page" do
          do_get
          expect(@response).to redirect_to(account_service_path(@account.id,
                                                            @service.id))
        end

        specify "should write request to change ISO of VM" do
          iso = 'OpenBSD-5.4-amd64-install54.iso'
          s = "cdrom-iso #{$ISO_BASE}/#{iso}"
          expect(@vm).to receive(:set_iso!).with(iso) { true }
          do_get(:iso_file => iso)
        end
      end

      context "without valid ISO filename" do
        specify "should redirect to service page" do
          do_get(:iso_file => 'lskjdlfdjf')
          expect(@response).to redirect_to(account_service_path(@account.id,
                                                            @service.id))
        end

        specify "should not set flash notice" do
          do_get(:iso_file => 'lskjdlfdjf')
          expect(flash[:notice_for_vm_iso]).to be_nil
        end
      end
    end

    context "with invalid VM" do

      before do
        allow(@account).to receive(:find_virtual_machine_by_id).with('999').and_return(nil)
      end

      specify "should not set flash notice" do
        do_get(:id => 999)
        expect(flash[:notice_for_vm_iso]).to be_nil
      end

      specify "should redirect to service page" do
        do_get(:id => 999)
        expect(@response).to redirect_to(account_service_path(@account.id,
                                                              @service.id))
      end
    end
  end

  context "write_request()" do
    specify "should write request with parameters" do
      vm = @vm
      ts = 1234567890

      %w(start shutdown destroy).each do |command|
        io = double("io")
        expect(io).to receive(:puts).with("#{command} #{vm.uuid} #{vm.host} ")

        allow(Time).to receive(:new).and_return(double("time", :to_i => ts))
        expect(File).to receive(:open).with("tmp/requests/#{vm.uuid}-#{ts}", "w").and_yield(io)

        VirtualMachinesController.new.instance_eval do
          write_request(vm, "#{command}")
        end
      end
    end
  end

  context "ssh_key" do

    def do_get(opts = {})
      get :ssh_key, { :account_id => @account.id, :service_id => @service.id,
                      :id => @vm.id }.merge(opts)
    end

    specify "should render SSH key submission form" do
      do_get
      expect(@response).to be_success
      expect(@response).to render_template('ssh_key')
    end
  end

  context "ssh_key_post" do

    before do
      @single_key = "ssh-rsa foo label"
      @two_keys   = "ssh-rsa foo label\nssh-dsa bar label"

      # We don't want SSH to actually execute
      allow(controller).to receive(:ssh_key_send).and_return(nil)
    end

    def do_post(opts = {})
      post :ssh_key_post, { :account_id => @account.id, :service_id => @service.id,
                            :id => @vm.id, :keys => @single_key }.merge(opts)
    end

    specify "should submit key" do
      # The order here is important; do_post must go after the should_receive()

      expect(@controller).to receive(:ssh_key_send).with(@vm.console_login, @single_key, false)
      do_post
    end

    specify "should submit multiple keys" do
      # The order here is important; do_post must go after the should_receive()

      key1, key2 = @two_keys.split("\n")
      expect(@controller).to receive(:ssh_key_send).with(@vm.console_login, key1, false)
      expect(@controller).to receive(:ssh_key_send).with(@vm.console_login, key2, true)

      do_post(:keys => @two_keys)
    end

    specify "should acknowledge submission" do
      do_post
      expect(flash[:notice]).to eq 'Your SSH key(s) have been received and installed.  Thank you!'
    end

    specify "should redirect back to form" do
      do_post
      expect(@response).to redirect_to(ssh_key_account_service_virtual_machine_path(\
        @account.id, @service.id, @vm.id))
    end

    context "when key is empty" do

      specify "should display error" do
        do_post(:keys => '')
        expect(flash[:error]).to eq "Your submission was empty"
      end

      specify "should redirect back to form" do
        do_post(:keys => '')
        expect(@response).to redirect_to(ssh_key_account_service_virtual_machine_path(\
          @account.id, @service.id, @vm.id))
      end
    end
  end

  context "ssh_key_send" do

    before do
      @login = 'johndoe'
      @key   = 'ssh-rsa foo label'

      # We don't want SSH to actually execute
      allow(Kernel).to receive(:system).and_return(nil)
    end

    def do_ssh_key_send(login, key, append)
      VirtualMachinesController.new.instance_eval do
        ssh_key_send(login, key, append)
      end
    end

    specify "should execute shell command to submit key to console.cust (without append)" do
      expect(Kernel).to receive(:system).\
        with("ssh", "-o", "ConnectTimeout 5", "#{$KEYER}@#{$HOST_CONSOLE}", "add", '0', @login, @key)
      do_ssh_key_send(@login, @key, false)
    end

    specify "should execute shell command to submit key to console.cust (with append)" do
      expect(Kernel).to receive(:system).\
        with("ssh", "-o", "ConnectTimeout 5", "#{$KEYER}@#{$HOST_CONSOLE}", "add", '1', @login, @key)
      do_ssh_key_send(@login, @key, true)
    end
  end

end
