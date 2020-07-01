require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::BackupQuotasController do
  before(:context) do
    create_admin!
  end

  before do
    login_as_admin!
    @p = { server: 'backup.example.com' }
  end

  def mock_backup_quota(stubs = {})
    @mock_backup_quota ||= mock_model(BackupQuota, stubs)
  end

  describe 'responding to GET index' do
    it 'should expose all backup_quotas as @backup_quotas' do
      expect(BackupQuota).to receive(:all) { [mock_backup_quota] }
      get :index
      expect(assigns[:backup_quotas]).to eq([mock_backup_quota])
    end
  end

  describe 'responding to GET new' do
    it 'should expose a new backup_quota as @backup_quota' do
      expect(BackupQuota).to receive(:new) { mock_backup_quota }
      get :new
      expect(assigns[:backup_quota]).to eq(mock_backup_quota)
    end

    it 'should set @include_blank' do
      expect(BackupQuota).to receive(:new) { mock_backup_quota }
      get :new
      expect(assigns(:include_blank)).to be true
    end
  end

  describe 'responding to GET edit' do
    it 'should expose the requested backup_quota as @backup_quota' do
      expect(BackupQuota).to receive(:find).with('37') { mock_backup_quota }
      get :edit, params: { id: '37' }
      expect(assigns[:backup_quota]).to eq(mock_backup_quota)
    end

    it 'should redirect to the admin_backup_quotas list if backup_quota cannot be found' do
      allow(BackupQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      get :edit, params: { id: '999' }
      expect(response).to redirect_to(admin_backup_quotas_url)
    end

    it 'should set @include_blank' do
      expect(BackupQuota).to receive(:find).with('37') { mock_backup_quota }
      get :edit, params: { id: '37' }
      expect(assigns(:include_blank)).to be true
    end
  end

  describe 'responding to POST create' do
    def do_create
      post :create, params: { backup_quota: @p }
    end

    describe 'with valid params' do
      it 'should expose a newly created backup_quota as @backup_quota' do
        expect(BackupQuota).to receive(:new).with(@p) { mock_backup_quota(save: true) }
        do_create
        expect(assigns(:backup_quota)).to eq(mock_backup_quota)
      end

      it 'should redirect to all service codes' do
        allow(BackupQuota).to receive(:new) { mock_backup_quota(save: true) }
        do_create
        expect(response).to redirect_to(admin_backup_quotas_path)
      end
    end

    describe 'with invalid params' do
      it 'should expose a newly created but unsaved backup_quota as @backup_quota' do
        allow(BackupQuota).to receive(:new).with(@p) { mock_backup_quota(save: false) }
        do_create
        expect(assigns[:backup_quota]).to eq(mock_backup_quota)
        expect(assigns[:include_blank]).to be true
      end

      it "should re-render the 'new' template" do
        allow(BackupQuota).to receive(:new) { mock_backup_quota(save: false) }
        do_create
        expect(response).to render_template('new')
      end
    end
  end

  describe 'responding to PUT udpate' do
    def do_patch
      patch :update, params: { id: '37', backup_quota: @p }
    end

    describe 'with valid params' do
      it 'should update the requested backup_quota' do
        expect(BackupQuota).to receive(:find).with('37') { mock_backup_quota }
        expect(mock_backup_quota).to receive(:update_attributes).with(@p)
        do_patch
      end

      it 'should expose the requested backup_quota as @backup_quota' do
        allow(BackupQuota).to receive(:find) { mock_backup_quota(update_attributes: true) }
        do_patch
        expect(assigns[:backup_quota]).to eq(mock_backup_quota)
      end

      it 'should redirect to all backup quotas' do
        allow(BackupQuota).to receive(:find) { mock_backup_quota(update_attributes: true) }
        do_patch
        expect(response).to redirect_to(admin_backup_quotas_path)
      end
    end

    describe 'with invalid params' do
      it 'should expose the backup_quota as @backup_quota' do
        allow(BackupQuota).to receive(:find) { mock_backup_quota(update_attributes: false) }
        do_patch
        expect(assigns(:backup_quota)).to eq(mock_backup_quota)
      end

      it "should re-render the 'edit' template" do
        allow(BackupQuota).to receive(:find) { mock_backup_quota(update_attributes: false) }
        do_patch
        expect(response).to render_template('edit')
      end

      it 'should redirect to the admin_backup_quotas list if backup_quota cannot be found' do
        allow(BackupQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        put :update, params: { id: '999' }
        expect(response).to redirect_to(admin_backup_quotas_url)
      end
    end
  end

  describe 'responding to DELETE destroy' do
    def do_delete(id = '37')
      delete :destroy, params: { id: id }
    end

    it 'should destroy the requested backup_quotas' do
      expect(BackupQuota).to receive(:find).with('37') { mock_backup_quota }
      expect(mock_backup_quota).to receive(:destroy)
      do_delete
    end

    it 'should redirect to the admin_backup_quotas list' do
      allow(BackupQuota).to receive(:find) { mock_backup_quota(destroy: true) }
      do_delete(1)
      expect(response).to redirect_to(admin_backup_quotas_url)
    end

    it 'should set flash[:error] if destroy() raises AR exception' do
      bad_monkey = mock_model(BackupQuota)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'ju baby no good')
      allow(BackupQuota).to receive(:find).and_return(bad_monkey)
      do_delete(1)
      expect(flash[:error]).to_not be_nil
    end

    it 'should redirect to the admin_backup_quotas list if backup_quota cannot be found' do
      allow(BackupQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_delete(999)
      expect(response).to redirect_to(admin_backup_quotas_url)
    end
  end
end
