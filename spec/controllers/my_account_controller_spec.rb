require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

describe MyAccountController do
  before(:context) do
    create_user!
  end

  describe 'dashboard action' do
    describe 'after good login' do
      before do
        login_as_user!
      end

      it 'should be success' do
        get :dashboard
        expect(response).to be_successful
      end

      it 'should render dashboard template' do
        get :dashboard
        expect(response).to render_template('my_account/dashboard')
      end

      it 'should enable summary view' do
        get :dashboard
        expect(assigns(:enable_summary_view)).to be true
      end
    end
  end
end
