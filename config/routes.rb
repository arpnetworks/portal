Rails.application.routes.draw do
  # ===========================
  # BEGIN: Copy from old Portal
  # ===========================

  resources :accounts do
    collection do
      get  'forgot_password'
      post 'forgot_password_post'
      get  'login'
      post 'login_attempt'
      get  'logout'
    end

    resources :services do
      collection do
        post 'confirm'
        post 'confirm_done'
        get  'remove'
      end

      member do
        patch 'update_label'
      end

      resources :virtual_machines do
        member do
          post 'boot'
          post 'shutdown'
          post 'shutdown_hard'
          get  'ssh_key'
          post 'ssh_key_post'
          post 'iso_change'
          post 'advanced_parameter'
        end
      end
      resources :ip_blocks
      resources :bandwidth_quotas
      resources :backup_quotas do
        member do
          get  'ssh_key'
          post 'ssh_key_post'
        end
      end
      resources :bgp_sessions
    end

    resources :dns_records do
      collection do
        get  'reverse_dns'
      end
    end
    resources :credit_cards
    resources :invoices do
      collection do
        get  'pay'
        post 'pay_confirm'
      end
    end
    resources :jobs
  end

  get '/noVNC/console', controller: 'virtual_machines', action: 'console'

  get '/dashboard', controller: 'my_account', action: 'dashboard', as: 'dashboard'

  namespace :admin do
    resources :accounts
    resources :invoices
    resources :services
    resources :service_codes
    resources :virtual_machines do
      member do
        post 'monitoring_reminder_post'
      end
    end
    resources :ip_blocks do
      collection do
        get  'tree'
      end

      member do
        get  'subnet'
        get  'swip'
        post 'swip_submit'
      end
    end
    resources :bandwidth_quotas
    resources :backup_quotas
    resources :bgp_sessions
    resources :bgp_sessions_prefixes
    resources :vlans do
      member do
        post 'shutdown'
        post 'restore'
      end
    end
    resources :jobs do
      member do
        post 'retry'
      end
    end
  end

  get 'admin',         controller: 'admin/head_quarters', action: 'index'

  # Switch user and search
  post 'admin/su',     controller: 'admin/head_quarters', action: 'su'
  get  'admin/search', controller: 'admin/head_quarters', action: 'search'

  # Other
  get "admin/whoami",  controller: 'admin/head_quarters', action: 'whoami'

  # Reports
  get "admin/reports/services", controller: 'admin/reports', action: 'services'

  namespace :api do
    namespace :v1 do
      namespace :internal do
        # TODO from below

        # Legacy
        get 'console_logins',            controller: 'utils', action: 'console_logins'
        get 'console_passwd_file',       controller: 'utils', action: 'console_passwd_file'
        get 'console_passwd_file/:host', controller: 'utils', action: 'console_passwd_file'
        get 'redis/ping',                controller: 'utils', action: 'redis_ping'

        # Other
        get 'jobs/health', controller: 'utils', action: 'job_queue_health'
      end
    end
  end

  # # Internal API
  # map.namespace(:api) do |api|
  #   api.namespace(:v1) do |v1|
  #     v1.namespace(:internal) do |internal|
  #       internal.connect 'jobs/:id/event/:event',        :controller => 'jobs', :action => 'event', :conditions => { :method => :put }
  #       internal.connect 'jobs/:id/event/:event/:args',  :controller => 'jobs', :action => 'event', :conditions => { :method => :put }
  #       internal.connect 'virtual_machines/:uuid/status/:status', :controller => 'virtual_machines',
  #                                                                 :action     => 'status',
  #                                                                 :conditions => { :method => :put }
  #       internal.connect 'virtual_machines/statuses', :controller => 'virtual_machines',
  #                                                     :action     => 'statuses',
  #                                                     :conditions => { :method => :put }
  #       # Provisioning
  #       internal.connect 'provisioning/:mac_address/config.tar.gz', :controller => 'provisioning',
  #                                                                   :action     => 'config'
  #     end
  #   end
  # end

  root controller: 'accounts', action: 'login'

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
