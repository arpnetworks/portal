require File.expand_path(File.dirname(__FILE__) + '/../../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../arp_spec_helper')

describe Admin::BandwidthQuotasController do
  before(:context) do
    create_admin!
  end

  before do
    login_as_admin!
    @p = { 'commit': '10000' }
  end

  def mock_bandwidth_quota(stubs = {})
    @mock_bandwidth_quota ||= mock_model(BandwidthQuota, stubs)
  end

  describe 'responding to GET index' do
    it 'should expose all bandwidth_quotas as @bandwidth_quotas' do
      bandwidth_quotas = double('All bandwidth_quotas')
      expect(BandwidthQuota).to receive(:paginate) { bandwidth_quotas }
      allow(bandwidth_quotas).to receive(:order) { [mock_bandwidth_quota] }

      get :index
      expect(assigns[:bandwidth_quotas]).to eq([mock_bandwidth_quota])
    end
  end

  describe 'responding to GET new' do
    it 'should expose a new bandwidth_quota as @bandwidth_quota' do
      expect(BandwidthQuota).to receive(:new) { mock_bandwidth_quota }
      get :new
      expect(assigns[:bandwidth_quota]).to eq(mock_bandwidth_quota)
    end

    it 'should set @include_blank' do
      expect(BandwidthQuota).to receive(:new) { mock_bandwidth_quota }
      get :new
      expect(assigns[:include_blank]).to be true
    end
  end

  describe 'responding to GET edit' do
    it 'should expose the requested bandwidth_quota as @bandwidth_quota' do
      expect(BandwidthQuota).to receive(:find).with('37') { mock_bandwidth_quota }
      get :edit, id: '37'
      expect(assigns[:bandwidth_quota]).to eq(mock_bandwidth_quota)
    end

    it 'should redirect to the admin_bandwidth_quotas list if bandwidth_quota cannot be found' do
      allow(BandwidthQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      get :edit, id: '999'
      expect(response).to redirect_to(admin_bandwidth_quotas_url)
    end

    it 'should set @include_blank' do
      expect(BandwidthQuota).to receive(:find).with('37') { mock_bandwidth_quota }
      get :edit, id: '37'
      expect(assigns[:include_blank]).to be true
    end
  end

  describe 'responding to POST create' do
    def do_create(bandwidth_quota = nil)
      post :create, bandwidth_quota: (bandwidth_quota || @p)
    end

    describe 'with valid params' do
      it 'should expose a newly created bandwidth_quota as @bandwidth_quota' do
        expect(BandwidthQuota).to receive(:new).with(@p) { mock_bandwidth_quota(save: true) }
        do_create
        expect(assigns[:bandwidth_quota]).to eq(mock_bandwidth_quota)
      end

      it 'should redirect to all service codes' do
        allow(BandwidthQuota).to receive(:new) { mock_bandwidth_quota(save: true) }
        do_create(bandwidth_quota: {})
        expect(response).to redirect_to(admin_bandwidth_quotas_path)
      end
    end

    describe 'with invalid params' do
      it 'should expose a newly created but unsaved bandwidth_quota as @bandwidth_quota' do
        allow(BandwidthQuota).to receive(:new).with(@p) { mock_bandwidth_quota(save: false) }
        do_create
        expect(assigns(:bandwidth_quota)).to eq(mock_bandwidth_quota)
        expect(assigns[:include_blank]).to be true
      end

      it "should re-render the 'new' template" do
        allow(BandwidthQuota).to receive(:new) { mock_bandwidth_quota(save: false) }
        do_create(bandwidth_quota: {})
        expect(response).to render_template('new')
      end
    end
  end

  describe 'responding to PATCH udpate' do
    def do_update(id = '37')
      patch :update, id: id, bandwidth_quota: @p
    end

    describe 'with valid params' do
      it 'should update the requested bandwidth_quota' do
        expect(BandwidthQuota).to receive(:find).with('37') { mock_bandwidth_quota }
        expect(mock_bandwidth_quota).to receive(:update).with(@p)
        do_update
      end

      it 'should expose the requested bandwidth_quota as @bandwidth_quota' do
        allow(BandwidthQuota).to receive(:find) { mock_bandwidth_quota(update: true) }
        do_update
        expect(assigns[:bandwidth_quota]).to eq(mock_bandwidth_quota)
      end

      it 'should redirect to all bandwidth quotas' do
        allow(BandwidthQuota).to receive(:find) { mock_bandwidth_quota(update: true) }
        do_update
        expect(response).to redirect_to(admin_bandwidth_quotas_path)
      end
    end

    describe 'with invalid params' do
      it 'should expose the bandwidth_quota as @bandwidth_quota' do
        allow(BandwidthQuota).to receive(:find) { mock_bandwidth_quota(update: false) }
        do_update
        expect(assigns(:bandwidth_quota)).to eq(mock_bandwidth_quota)
      end

      it "should re-render the 'edit' template" do
        allow(BandwidthQuota).to receive(:find) { mock_bandwidth_quota(update: false) }
        do_update
        expect(response).to render_template('edit')
      end

      it 'should redirect to the admin_bandwidth_quotas list if bandwidth_quota cannot be found' do
        allow(BandwidthQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
        do_update
        expect(response).to redirect_to(admin_bandwidth_quotas_url)
      end
    end
  end

  describe 'responding to DELETE destroy' do
    def do_destroy(id = '37')
      delete :destroy, id: id
    end

    it 'should destroy the requested bandwidth_quotas' do
      expect(BandwidthQuota).to receive(:find).with('37') { mock_bandwidth_quota }
      expect(mock_bandwidth_quota).to receive(:destroy)
      do_destroy
    end

    it 'should redirect to the admin_bandwidth_quotas list' do
      allow(BandwidthQuota).to receive(:find) { mock_bandwidth_quota(destroy: true) }
      do_destroy
      expect(response).to redirect_to(admin_bandwidth_quotas_url)
    end

    it 'should set flash[:error] if destroy() raises AR exception' do
      bad_monkey = double(BandwidthQuota)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'bad monkey')
      allow(BandwidthQuota).to receive(:find) { bad_monkey }
      do_destroy
      expect(flash[:error]).to_not be_nil
    end

    it 'should redirect to the admin_bandwidth_quotas list if bandwidth_quota cannot be found' do
      allow(BandwidthQuota).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_destroy
      expect(response).to redirect_to(admin_bandwidth_quotas_url)
    end
  end
end
