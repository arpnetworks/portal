module UserCreationHelper
  def create_admin!
    Account.find_by(login: 'admin') || create(:account_admin)
  end

  def create_user!(opts = {})
    login = opts[:login] || 'user'
    @user = Account.find_by(login: login) || create(:account_user, login: login)

    if opts[:create_service]
      # A regular user should have at least one service
      @user.services << create(:service, description: 'cool stuff') if @user.services.empty?
    end

    @user
  end
end