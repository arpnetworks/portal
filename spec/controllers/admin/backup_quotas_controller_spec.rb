require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../my_spec_helper')

describe Admin::BackupQuotasController do
  fixtures :accounts

  before :all do
    Account.delete_all("id > 2")
  end

  before do
    login!
  end

  def mock_backup_quota(stubs={})
    @mock_backup_quota ||= mock_model(BackupQuota, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all backup_quotas as @backup_quotas" do
      BackupQuota.should_receive(:find).with(:all).and_return([mock_backup_quota])
      mock_backup_quota.should_receive(:backup_quota).any_number_of_times
      get :index
      assigns[:backup_quotas].should == [mock_backup_quota]
    end

  end

  describe "responding to GET new" do
  
    it "should expose a new backup_quota as @backup_quota" do
      BackupQuota.should_receive(:new).and_return(mock_backup_quota)
      get :new
      assigns[:backup_quota].should equal(mock_backup_quota)
    end

    it "should set @include_blank" do
      BackupQuota.should_receive(:new).and_return(mock_backup_quota)
      get :new
      assigns(:include_blank).should be_true
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested backup_quota as @backup_quota" do
      BackupQuota.should_receive(:find).with("37").and_return(mock_backup_quota)
      get :edit, :id => "37"
      assigns[:backup_quota].should equal(mock_backup_quota)
    end

    it "should redirect to the admin_backup_quotas list if backup_quota cannot be found" do
      BackupQuota.stub!(:find).and_raise(ActiveRecord::RecordNotFound)
      get :edit, :id => "999"
      response.should redirect_to(admin_backup_quotas_url)
    end

    it "should set @include_blank" do
      BackupQuota.should_receive(:find).with("37").and_return(mock_backup_quota)
      get :edit, :id => "37"
      assigns(:include_blank).should be_true
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
