class Admin::HeadQuartersController < ProtectedController
  before_action :is_arp_admin?, :except => [:search, :index]
  before_action :is_arp_sub_admin?, :only => [:search, :index]
  before_action :set_admin_state

  protect_from_forgery :except => [:su]

  def su
    if request.post?
      if @is_super_admin
        @account = Account.find_by_login(params[:user][:login])
        session[:account_id] = @account.id
        redirect_to dashboard_path and return
      end
    end

    redirect_to admin_path
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "You took a wrong turn at Albuquerque"
    redirect_to admin_path
  end

  def whoami
    render plain: %x{whoami}
  end

  def search
    query = params[:query]
    q = "%#{query}%"

    s = ''
    qs = []
    %w(id login first_name last_name company address1 address2
       city state zip country email email2 email_billing).each do |field|
      s += "#{field} like ? or "
      qs << q
    end

    s = s[0, s.length - 4]
    c = [s] + qs

    @accounts = Account.where(c)

    @ip_blocks = IpBlock.where(['cidr like ? or vlan = ?', q, query]).order('vlan')

    s = ''
    qs = []
    %w(id title description label).each do |field|
      s += "#{field} like ? or "
      qs << q
    end

    s = s[0, s.length - 4]
    c = [s] + qs

    @services = Service.where(c)

    s = ''
    qs = []
    %w(mac_address ip_address ipv6_address).each do |field|
      s += "#{field} like ? or "
      qs << q
    end

    s = s[0, s.length - 4]
    c = [s] + qs

    @virtual_machines_interfaces = VirtualMachinesInterface.where(c)
    @virtual_machines = @virtual_machines_interfaces.map { |o| o.virtual_machine }.compact

    if @account = IpBlock.account(query)
      @ip_blocks += @account.ip_blocks
    end
  end

  protected

  def set_admin_state
    @enable_admin_view = true unless params[:cv]

    @sub_admin_view = false # No longer used

    @is_super_admin = $SUPER_ADMINS.include?(@account.login)

    # If the 'cv' param is set, then the views will be rendered as if a
    # customer was logged in.  cv = "customer view".  A quick shortcut to
    # check if what they see is OK.
  end
end
