Rails.application.routes.draw do
  # ===========================
  # BEGIN: Copy from old Portal
  # ===========================

  map.resources :accounts, :collection => { :forgot_password      => :get,
                                            :forgot_password_post => :post,
                                            :login                => :get,
                                            :login_attempt        => :post,
                                            :logout               => :get
                                           } do |accounts|
    accounts.resources :services, {
      :collection => {
        :confirm      => :post,
        :confirm_done => :post,
        :remove       => :get
      },
      :member => {
        :update_label => :put }} do |services|
      services.resources :virtual_machines, :member => {
        :boot          => :post,
        :shutdown      => :post,
        :shutdown_hard => :post,
        :ssh_key       => :get,
        :ssh_key_post  => :post,
        :iso_change    => :post,
        :advanced_parameter => :post
      }
      services.resources :ip_blocks
      services.resources :bandwidth_quotas
      services.resources :backup_quotas, :member => {
        :ssh_key       => :get,
        :ssh_key_post  => :post
      }
      services.resources :bgp_sessions
    end

    accounts.resources :dns_records, :collection => {
      :reverse_dns => :get
    }

    accounts.resources :credit_cards
    accounts.resources :invoices, :collection => {
      :pay         => :get,
      :pay_confirm => :post
    }
    accounts.resources :jobs
  end

  map.connect '/noVNC/console', :controller => 'virtual_machines', :action => 'console'

  map.dashboard '/dashboard', :controller => 'my_account', :action => 'dashboard'

  map.namespace(:admin) do |admin|
    admin.resources :accounts
    admin.resources :invoices
    admin.resources :services
    admin.resources :service_codes
    admin.resources :virtual_machines,
      :member => {
        :monitoring_reminder_post => :post }
    admin.resources :ip_blocks, :collection => { :tree   => :get },
                                :member     => { :subnet => :get,
                                                 :swip   => :get,
                                                 :swip_submit => :post }
    admin.resources :bandwidth_quotas
    admin.resources :backup_quotas
    admin.resources :bgp_sessions
    admin.resources :bgp_sessions_prefixes
    admin.resources :vlans, :member => {
      :shutdown => :post,
      :restore  => :post
    }
    admin.resources :jobs, :member => {
      :retry => :post
    }
  end
  map.admin "admin", :controller => 'admin/head_quarters', :action => 'index'

  # Switch user and search
  map.connect "admin/su", :controller => 'admin/head_quarters', :action => 'su'
  map.connect "admin/search", :controller => 'admin/head_quarters', :action => 'search'

  # Reports
  map.connect "admin/reports/services", :controller => 'admin/reports', :action => 'services'

  # Other
  map.connect "admin/whoami", :controller => 'admin/head_quarters', :action => 'whoami'

  # Internal API
  map.namespace(:api) do |api|
    api.namespace(:v1) do |v1|
      v1.namespace(:internal) do |internal|
        internal.connect 'jobs/:id/event/:event',        :controller => 'jobs', :action => 'event', :conditions => { :method => :put }
        internal.connect 'jobs/:id/event/:event/:args',  :controller => 'jobs', :action => 'event', :conditions => { :method => :put }

        internal.connect 'virtual_machines/:uuid/status/:status', :controller => 'virtual_machines',
                                                                  :action     => 'status',
                                                                  :conditions => { :method => :put }
        internal.connect 'virtual_machines/statuses', :controller => 'virtual_machines',
                                                      :action     => 'statuses',
                                                      :conditions => { :method => :put }

        # Provisioning
        internal.connect 'provisioning/:mac_address/config.tar.gz', :controller => 'provisioning',
                                                                    :action     => 'config'

        # Legacy
        internal.connect 'console_logins',            :controller => 'utils', :action => 'console_logins'
        internal.connect 'console_passwd_file',       :controller => 'utils', :action => 'console_passwd_file'
        internal.connect 'console_passwd_file/:host', :controller => 'utils', :action => 'console_passwd_file'
        internal.connect 'redis/ping', :controller => 'utils', :action => 'redis_ping'

        # Other
        internal.connect 'jobs/health', :controller => 'utils', :action => 'job_queue_health'
      end
    end
  end

  map.root :controller => 'accounts', :action => 'login'

  # =========================
  # END: Copy from old Portal
  # =========================

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
