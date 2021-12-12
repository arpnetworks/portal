require 'rails_helper'

describe Admin::ServiceCodesController do

  before do
    @admin = create_admin!
    sign_in @admin
  end

  def mock_service_code(stubs = {})
    @mock_service_code ||= mock_model(ServiceCode, stubs)
  end

  describe 'responding to GET index' do
    it 'should expose all admin_service_codes as @admin_service_codes' do
      expect(ServiceCode).to receive(:all) { [mock_service_code] }
      get :index
      expect(assigns[:service_codes]).to eq([mock_service_code])
    end

    describe 'with mime type of xml' do
      it 'should render all admin_service_codes as xml' do
        request.env['HTTP_ACCEPT'] = 'application/xml'

        xml = 'generated XML'
        service_codes = double('Array of ServiceCode', to_xml: xml)

        expect(ServiceCode).to receive(:all) { service_codes }
        get :index
        expect(response.body).to eq(xml)
      end
    end
  end

  describe 'responding to GET show' do
    it 'should expose the requested service_codes as @service_codes' do
      service_code = double(ServiceCode)
      expect(ServiceCode).to receive(:find).with('37') { service_code }
      get :show, params: { id: '37' }
      expect(assigns[:service_code]).to eq(service_code)
    end

    describe 'with mime type of xml' do
      it 'should render the requested service_codes as xml' do
        request.env['HTTP_ACCEPT'] = 'application/xml'

        xml = 'generated XML'
        service_code = double(ServiceCode, to_xml: xml)

        expect(ServiceCode).to receive(:find).with('37') { service_code }
        get :show, params: { id: '37' }
        expect(response.body).to eq(xml)
      end
    end
  end

  describe 'responding to GET new' do
    it 'should expose a new service_codes as @service_codes' do
      expect(ServiceCode).to receive(:new) { mock_service_code }
      get :new
      expect(assigns[:service_code]).to eq(mock_service_code)
    end
  end

  describe 'responding to GET edit' do
    it 'should expose the requested service_codes as @service_codes' do
      expect(ServiceCode).to receive(:find).with('37') { mock_service_code }
      get :edit, params: { id: '37' }
      expect(assigns[:service_code]).to eq(mock_service_code)
    end
  end

  describe 'responding to POST create' do
    before do
      @p = { name: 'foo' }
    end

    def do_create
      post :create, params: { service_code: @p }
    end

    describe 'with valid params' do
      it 'should expose a newly created service_codes as @service_codes' do
        expect(ServiceCode).to receive(:new).with(ActionController::Parameters.new(@p).permit(:name)) { mock_service_code(save: true) }
        do_create
        expect(assigns(:service_code)).to eq(mock_service_code)
      end

      it 'should redirect to all service codes' do
        allow(ServiceCode).to receive(:new) { mock_service_code(save: true) }
        do_create
        expect(response).to redirect_to(admin_service_codes_path)
      end
    end

    describe 'with invalid params' do
      it 'should expose a newly created but unsaved service_codes as @service_codes' do
        allow(ServiceCode).to receive(:new).with(ActionController::Parameters.new(@p).permit(:name)) { mock_service_code(save: false) }
        do_create
        expect(assigns(:service_code)).to eq(mock_service_code)
      end

      it "should re-render the 'new' template" do
        allow(ServiceCode).to receive(:new) { mock_service_code(save: false) }
        do_create
        expect(response).to render_template('new')
      end
    end
  end

  describe 'responding to PUT udpate' do
    describe 'with valid params' do
      it 'should update the requested service_codes' do
        p = { name: 'BANDWIDTH' }
        expect(ServiceCode).to receive(:find).with('37') { mock_service_code }
        expect(mock_service_code).to receive(:update)
        put :update, params: { id: '37', service_code: p }
      end

      it 'should expose the requested service_codes as @service_codes' do
        allow(ServiceCode).to receive(:find) { mock_service_code(update: true) }
        put :update, params: { id: '1', service_code: { name: 'FOO' } }
        expect(assigns(:service_code)).to eq(mock_service_code)
      end

      it 'should redirect to all service codes' do
        allow(ServiceCode).to receive(:find) { mock_service_code(update: true) }
        put :update, params: { id: '1', service_code: { name: 'FOO' } }
        expect(response).to redirect_to(admin_service_codes_path)
      end
    end

    describe 'with invalid params' do
      it "should re-render the 'edit' template" do
        allow(ServiceCode).to receive(:find) { mock_service_code(update: false) }
        put :update, params: { id: '1', service_code: { name: 'FOO' } }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'responding to DELETE destroy' do
    it 'should destroy the requested service_codes' do
      expect(ServiceCode).to receive(:find).with('37') { mock_service_code }
      expect(mock_service_code).to receive(:destroy)
      delete :destroy, params: { id: '37' }
    end

    it 'should redirect to the admin_service_codes list' do
      allow(ServiceCode).to receive(:find) { mock_service_code(destroy: true) }
      delete :destroy, params: { id: '1' }
      expect(response).to redirect_to(admin_service_codes_url)
    end

    it 'should set flash[:error] if destroy() raises AR exception' do
      bad_monkey = instance_double(ServiceCode)
      allow(ServiceCode).to receive(:find) { bad_monkey }
      expect(bad_monkey).to receive(:destroy).and_raise(ActiveRecord::StatementInvalid, 'doh!')
      delete :destroy, params: { id: '1' }
      expect(flash[:error]).to_not be_nil
    end
  end
end
