require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::BackupQuotasController do

  before(:context) do
    create :account_admin
  end

  before do
    login!
    allow(@controller).to receive(:is_arp_admin?)     { true }
    allow(@controller).to receive(:is_arp_sub_admin?) { true }
  end

  def mock_backup_quota(stubs={})
    @mock_backup_quota ||= mock_model(BackupQuota, stubs)
  end

  describe "responding to GET index" do

    it "should expose all backup_quotas as @backup_quotas" do
      expect(BackupQuota).to receive(:all) { [mock_backup_quota] }
      get :index
      expect(assigns[:backup_quotas]).to eq([mock_backup_quota])
    end

  end

  describe "responding to GET new" do

    it "should expose a new backup_quota as @backup_quota" do
      expect(BackupQuota).to receive(:new) { mock_backup_quota }
      get :new
      expect(assigns[:backup_quota]).to eq(mock_backup_quota)
    end

    it "should set @include_blank" do
      expect(BackupQuota).to receive(:new) { mock_backup_quota }
      get :new
      expect(assigns(:include_blank)).to be true
    end

  end

  describe "responding to GET edit" do

    it "should expose the requested backup_quota as @backup_quota" do
      expect(BackupQuota).to receive(:find).with("37") { mock_backup_quota }
      get :edit, :id => "37"
      expect(assigns[:backup_quota]).to eq(mock_backup_quota)
    end

    it "should redirect to the admin_backup_quotas list if backup_quota cannot be found" do
      allow(BackupQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      get :edit, :id => "999"
      expect(response).to redirect_to(admin_backup_quotas_url)
    end

    it "should set @include_blank" do
      expect(BackupQuota).to receive(:find).with("37") { mock_backup_quota }
      get :edit, :id => "37"
      expect(assigns(:include_blank)).to be true
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do

      it "should expose a newly created backup_quota as @backup_quota" do
        BackupQuota.should_receive(:new).with({'these' => 'params'}).and_return(mock_backup_quota(:save => true))
        post :create, :backup_quota => {:these => 'params'}
        assigns(:backup_quota).should equal(mock_backup_quota)
      end

      it "should redirect to all service codes" do
        BackupQuota.stub!(:new).and_return(mock_backup_quota(:save => true))
        post :create, :backup_quota => {}
        response.should redirect_to(admin_backup_quotas_path)
      end

    end

    describe "with invalid params" do

      it "should expose a newly created but unsaved backup_quota as @backup_quota" do
        BackupQuota.stub!(:new).with({'these' => 'params'}).and_return(mock_backup_quota(:save => false))
        post :create, :backup_quota => {:these => 'params'}
        assigns(:backup_quota).should equal(mock_backup_quota)
        assigns(:include_blank).should == true
      end

      it "should re-render the 'new' template" do
        BackupQuota.stub!(:new).and_return(mock_backup_quota(:save => false))
        post :create, :backup_quota => {}
        response.should render_template('new')
      end

    end

  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested backup_quota" do
        BackupQuota.should_receive(:find).with("37").and_return(mock_backup_quota)
        mock_backup_quota.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :backup_quota => {:these => 'params'}
      end

      it "should expose the requested backup_quota as @backup_quota" do
        BackupQuota.stub!(:find).and_return(mock_backup_quota(:update_attributes => true))
        put :update, :id => "1"
        assigns(:backup_quota).should equal(mock_backup_quota)
      end

      it "should redirect to all backup quotas" do
        BackupQuota.stub!(:find).and_return(mock_backup_quota(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(admin_backup_quotas_path)
      end

    end

    describe "with invalid params" do

      it "should expose the backup_quota as @backup_quota" do
        BackupQuota.stub!(:find).and_return(mock_backup_quota(:update_attributes => false))
        put :update, :id => "1"
        assigns(:backup_quota).should equal(mock_backup_quota)
      end

      it "should re-render the 'edit' template" do
        BackupQuota.stub!(:find).and_return(mock_backup_quota(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

      it "should redirect to the admin_backup_quotas list if backup_quota cannot be found" do
        BackupQuota.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
        put :update, :id => "999"
        response.should redirect_to(admin_backup_quotas_url)
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested backup_quotas" do
      BackupQuota.should_receive(:find).with("37").and_return(mock_backup_quota)
      mock_backup_quota.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "should redirect to the admin_backup_quotas list" do
      BackupQuota.stub!(:find).and_return(mock_backup_quota(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(admin_backup_quotas_url)
    end

    it "should set flash[:error] if destroy() raises AR exception" do
      bad_monkey = mock(BackupQuota)
      bad_monkey.should_receive(:destroy).and_raise(ActiveRecord::StatementInvalid)
      BackupQuota.stub!(:find).and_return(bad_monkey)
      delete :destroy, :id => "1"
      flash[:error].should_not be_nil
    end

    it "should redirect to the admin_backup_quotas list if backup_quota cannot be found" do
      BackupQuota.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      delete :destroy, :id => "999"
      response.should redirect_to(admin_backup_quotas_url)
    end
  end

end
