require 'rails_helper'

describe Admin::IpBlocksController do

  before do
    @admin = create_admin!
    sign_in @admin
    @ip_block = mock_model(IpBlock)
    @params = { id: @ip_block.id }
  end

  def do_get(opts = {})
    get :index, params: opts
  end

  describe 'handling GET /admin/ip_blocks/new' do
    def do_get(opts = {})
      get :new, params: opts
    end

    it 'should display new ip_block form' do
      do_get
      expect(assigns(:ip_block)).to be_new_record
      expect(response).to be_successful
    end

    it 'should set @include_blank' do
      do_get
      expect(assigns(:include_blank)).to be true
    end

    it 'should let parent_block be selected automatically from params' do
      @ip_block_smaller = create :ip_block_smaller
      do_get(@params.merge(ip_block: { ip_block_id: @ip_block_smaller.id }))
      expect(assigns(:ip_block).parent_block.id).to eq @ip_block_smaller.id
    end

    it 'should default seq to 100' do
      do_get
      expect(assigns(:ip_block).seq).to eq 100
    end

    it 'should allow override seq' do
      do_get(ip_block: { seq: 90 })
      expect(assigns(:ip_block).seq).to eq 90
    end
  end

  describe 'handling POST /admin/ip_blocks' do
    def do_post(opts = {})
      post :create, params: opts
    end

    it 'should create new ip_block' do
      num_records = IpBlock.count
      do_post(@params.merge(ip_block: { cidr: '208.79.88.128/28' }))
      expect(IpBlock.count).to eq(num_records + 1)
      expect(response).to redirect_to(tree_admin_ip_blocks_path)
      expect(flash[:notice]).to_not be_nil
    end

    it 'should go back to new page if error creating' do
      expect(IpBlock).to receive(:new) { mock_model(IpBlock, save: false) }
      do_post(@params.merge(ip_block: { cidr: 'foo' }))
      expect(response).to render_template('admin/ip_blocks/new')
      expect(assigns(:include_blank)).to be true
    end

    it 'should allow empty service id' do
      do_post(@params.merge(ip_block: { cidr: '192.168.1.0/24', service_id: '' }))
      expect(response).to redirect_to(tree_admin_ip_blocks_path)
    end
  end

  describe 'handling GET /admin/ip_blocks' do
    it 'should display a list of IP blocks' do
      create :ip_block
      do_get
      expect(assigns(:ip_blocks)).to_not be_empty
      expect(response).to be_successful
      expect(response).to render_template('index')
    end
  end

  describe 'handling GET /admin/ip_blocks/tree' do
    def do_get(opts = {})
      get :tree, params: opts
    end

    it 'IP blocks should be the superblocks' do
      expect(IpBlock).to receive(:superblocks) { mock_model(IpBlock, includes: []) }
      do_get
    end
  end

  describe 'handling GET /admin/ip_blocks/1' do
    def do_get(opts = {})
      get :show, params: opts
    end

    it 'should show the ip_block' do
      @ip_block = mock_ip_block
      allow(IpBlock).to receive(:find) { @ip_block }
      do_get @params
      expect(response).to be_successful
      expect(response).to render_template('ip_blocks/show')
      expect(assigns(:ip_block).id).to eq @ip_block.id
    end

    it 'should redirect when the ip_block is not found' do
      allow(IpBlock).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get @params
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_ip_blocks_path)
    end
  end

  describe 'handling GET /admin/ip_blocks/1/edit' do
    def do_get(opts = {})
      get :edit, params: opts
    end

    it 'should show the ip_block' do
      @ip_block = mock_ip_block
      allow(IpBlock).to receive(:find) { @ip_block }
      do_get @params
      expect(response).to be_successful
      expect(assigns(:ip_block).id).to eq @ip_block.id
    end

    it 'should redirect when the ip_block is not found' do
      allow(IpBlock).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      do_get @params
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_ip_blocks_path)
    end

    it 'should set @include_blank' do
      allow(IpBlock).to receive(:find) { @ip_block }
      do_get @params
      expect(assigns(:include_blank)).to be true
    end
  end

  describe 'handling PUT /admin/ip_blocks/1/edit' do
    def do_put(opts = {})
      put :update, params: opts
    end

    it 'should update the ip_block' do
      @new_ip_block = { cidr: '10.0.1.128/28' }
      @ip_block = create :ip_block
      expect(@ip_block.cidr).to_not eq @new_ip_block[:cidr]
      allow(IpBlock).to receive(:find) { @ip_block }
      do_put(@params.merge(ip_block: @new_ip_block))
      expect(response).to redirect_to(edit_admin_ip_block_path(@ip_block))
      expect(flash[:notice]).to_not be_empty
      @reloaded_ip_block = IpBlock.find(@ip_block.id)
      expect(@reloaded_ip_block.cidr).to eq @new_ip_block[:cidr]
    end

    it 'should go back to edit page if error updating' do
      @ip_block = mock_model(IpBlock)
      allow(controller).to receive(:ip_block_params) { {} }
      allow(@ip_block).to receive(:update) { false }
      expect(IpBlock).to receive(:find).with(@ip_block.id.to_s) { @ip_block }
      do_put(@params.merge(id: @ip_block.id, ip_block: {}))
      expect(response).to render_template('admin/ip_blocks/edit')
    end

    it 'should redirect when the ip_block is not found' do
      do_put @params.merge(id: 999)
      expect(flash[:error]).to_not be_nil
      expect(response).to redirect_to(admin_ip_blocks_path)
    end

    it 'should allow empty service id' do
      allow(IpBlock).to receive(:find) { @ip_block }
      allow(@ip_block).to receive(:update) { true }
      do_put(@params.merge(id: @ip_block.id, ip_block: { service_id: '', cidr: '10.0.0.1/24' }))
      expect(response).to redirect_to(edit_admin_ip_block_path(@ip_block))
    end
  end

  def mock_ip_block(stubs = {})
    @mock_ip_block ||= mock_model(IpBlock, stubs)
  end

  describe 'responding to DELETE destroy' do
    before do
      @last_location = '/last'
      allow(controller).to receive(:last_location) { @last_location }
    end

    it 'should destroy the requested ip_blocks' do
      expect(IpBlock).to receive(:find).with('37') { mock_ip_block }
      expect(mock_ip_block).to receive(:destroy)
      delete :destroy, params: { id: '37' }
    end

    it 'should redirect to the location that brought us here' do
      allow(IpBlock).to receive(:find) { mock_ip_block(destroy: true) }
      delete :destroy, params: { id: '1' }
      expect(response).to redirect_to(@last_location)
    end

    it 'should set flash[:error] if destroy() raises AR exception' do
      bad_monkey = mock_model(IpBlock)
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'bad')
      allow(IpBlock).to receive(:find).and_return(bad_monkey)
      delete :destroy, params: { id: '1' }
      expect(flash[:error]).to_not be_nil
    end
  end

  describe 'handling GET /admin/ip_blocks/1/subnet' do
    it 'should provide available subnets when prefix length is provided' do
      @prefixlen = 28
      expect(IpBlock).to receive(:find).with('37') { mock_ip_block }

      expect(mock_ip_block).to receive(:subnets_available).with(@prefixlen, Strategy: :leftmost, limit: nil)
      get :subnet, params: { id: '37', prefixlen: @prefixlen }
    end
  end

  describe 'handling GET /admin/ip_blocks/1/swip' do
    before do
      @ip_block = build :ip_block
      allow(IpBlock).to receive(:find) { @ip_block }
    end

    def do_get(opts = {})
      get :swip, params: opts
    end

    it 'should be success' do
      do_get @params
      expect(response).to be_successful
    end

    it 'should render REASSIGN SIMPLE fill-in form' do
      do_get @params
      expect(response).to render_template('swip')
    end

    it 'should retreive ip block' do
      do_get @params
      expect(assigns(:ip_block)).to_not be_nil
    end

    it 'should retreive downstream organization' do
      allow(@ip_block).to receive(:account) { 'ACME Inc' }
      do_get @params
      expect(assigns(:downstream_org)).to_not be_nil
    end

    it "should set registration_action to 'N'" do
      do_get @params
      expect(assigns(:form).registration_action).to eq 'N'
    end
  end

  describe 'handling POST /admin/ip_block/1/swip_submit' do
    before do
      @ip_block = mock_model(IpBlock, origin_as: 25_795)
      allow(IpBlock).to receive(:find) { @ip_block }
    end

    def do_post(opts = {})
      post :swip_submit, params: opts
    end

    it 'should retreive registration_action from form' do
      %w[new modify remove].each do |registration_action|
        do_post @params.merge(form: { registration_action: registration_action })
        form = assigns(:form)
        expect(form.registration_action).to_not be_nil
        expect(form.registration_action).to eq registration_action
      end
    end

    it 'should retreive downstream organization info from form' do
      company = 'Starbucks'
      do_post @params.merge(downstream_org: { display_account_name: company })
      downstream_org = assigns(:downstream_org)
      expect(downstream_org).to_not be_nil
      expect(downstream_org.display_account_name).to eq company
    end

    it 'should not submit empty network name' do
      do_post @params.merge(form: { network_name: '' })
      expect(response).to render_template('swip')
    end
  end
end
