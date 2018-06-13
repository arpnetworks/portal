require File.expand_path(File.dirname(__FILE__) + '/../rails_helper')
require File.expand_path(File.dirname(__FILE__) + '/../arp_spec_helper')

describe AccountsController do
  before(:context) do
    @user = create_user!
  end

  describe AccountsController, "during account creation" do
    it "should not allow periods in login name" do
      post :create, :account => { :login => 'foobar.baz', :password => 'barbarbar',
                                  :password_confirmation => 'barbarbar',
                                  :email => 'foo@example.com' }

      expect(assigns(:account)).to_not be_valid
      expect(response).to render_template('new')
    end
  end

  describe AccountsController, "when logging in" do
    it "should remember the requested location in a non-logged-in state and redirect." do
      request.session[:return_to] = "http://www.google.com"
      post :login_attempt, :account => { :login => @user.login, :password => 'mysecret' }
      expect(response).to redirect_to("http://www.google.com")
    end

    it "should redirect to dashboard if already logged in" do
      login_as_user!
      get :login
      expect(response).to redirect_to(dashboard_path)
    end
  end
end

describe AccountsController do
  before(:context) do
    @user = create_user!
  end

  describe "Edit account" do
    before do
      login!(@user.login, 'mysecret')
    end

    it "should respond with success" do
      get :edit, :id => @user.id
      expect(@response).to be_success
    end

    it "should get account info from current logged in user" do
      get :edit, :id => @user.id
      expect(assigns(:account)).to eq @user
    end

    it "should not get account info from another user" do
      @other = create(:account_user, login: 'other')
      get :edit, :id => @other.id
      expect(assigns(:account)).to_not eq @other
    end
  end

  describe "Show account" do
    it "should redirect to edit" do
      @user = login_as_user!
      get :show, :id => @user.id
      expect(@response).to redirect_to(edit_account_path(@user))
    end
  end

  describe "Forgot password" do
    it "should not require login" do
      get :forgot_password
      expect(@response).to be_success
      expect(@response).to render_template('forgot_password')
    end
  end

end
