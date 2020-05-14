require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

context BackupQuotasController do

  before(:context) do
    create_user!
  end

  before do
    @account = login_as_user!

    @bq = mock_model(BackupQuota, server: 'foo.example.com', username: 'foo', quota: 200000)
    allow(@account).to receive(:find_backup_quota_by_id) { @bq }
    @service = mock_model(Service)
    allow(Service).to receive(:find).with(@service.id.to_s) { @service }
  end

  # I don't like that this spec is almost a copy of our first spec for
  # SSH key submissions in VirtualMachineController, but I have a
  # business to run...

  context "ssh_key" do
    def do_get(opts = {})
      get :ssh_key, { account_id: @account.id, service_id: @service.id,
                      id: @bq.id }.merge(opts)
    end

    specify "should render SSH key submission form" do
      do_get
      expect(response).to be_success
      expect(response).to render_template('virtual_machines/ssh_key')
    end
  end

  context "ssh_key_post" do
    before do
      @single_key = "ssh-rsa foo label"
      @two_keys   = "ssh-rsa foo label\nssh-dsa bar label"

      # We don't want SSH to actually execute
      allow(controller).to receive(:ssh_key_send) { nil }
    end

    def do_post(opts = {})
      post :ssh_key_post, { account_id: @account.id, service_id: @service.id,
                            id: @bq.id, keys: @single_key }.merge(opts)
    end

    specify "should submit key" do
      expect(controller).to receive(:ssh_key_send).with(@bq.server, @bq.username, @single_key, false, @bq.quota)
      do_post
    end

    specify "should submit multiple keys" do
      key1, key2 = @two_keys.split("\n")
      expect(controller).to receive(:ssh_key_send).with(@bq.server, @bq.username, key1, false, @bq.quota)
      expect(controller).to receive(:ssh_key_send).with(@bq.server, @bq.username, key2, true, @bq.quota)

      do_post(keys: @two_keys)
    end

    specify "should acknowledge submission" do
      do_post
      expect(flash[:notice]).to eq 'Your SSH key(s) have been received and installed.  Thank you!'
    end

    specify "should redirect back to form" do
      do_post
      expect(response).to redirect_to(ssh_key_account_service_backup_quota_path(\
        @account.id, @service.id, @bq.id))
    end

    context "when key is empty" do
      specify "should display error" do
        do_post(keys: '')
        expect(flash[:error]).to eq "Your submission was empty"
      end

      specify "should redirect back to form" do
        do_post(keys: '')
        expect(response).to redirect_to(ssh_key_account_service_backup_quota_path(\
          @account.id, @service.id, @bq.id))
      end
    end
  end

  context "ssh_key_send" do
    before do
      @server = 'localhost'
      @login = 'johndoe'
      @key   = 'ssh-rsa foo label'
      @quota = 5000000

      # We don't want SSH to actually execute
      allow(Kernel).to receive(:system) { nil }
    end

    def do_ssh_key_send(server, login, key, append, quota)
      BackupQuotasController.new.instance_eval do
        ssh_key_send(server, login, key, append, quota)
      end
    end

    specify "should execute shell command to submit key to console.cust (without append)" do
      expect(Kernel).to receive(:system).\
        with("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$KEYER}@#{@server}", "add", '0', @login, @quota.to_s, @key)

      do_ssh_key_send(@server, @login, @key, false, @quota)
    end

    specify "should execute shell command to submit key to console.cust (with append)" do
      expect(Kernel).to receive(:system).\
        with("/usr/bin/ssh", "-o", "ConnectTimeout=5", "#{$KEYER}@#{@server}", "add", '1', @login, @quota.to_s, @key)

      do_ssh_key_send(@server, @login, @key, true, @quota)
    end
  end



end
