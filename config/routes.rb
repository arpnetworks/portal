Rails.application.routes.draw do

  devise_scope :account do
    root to: 'accounts/sessions#new'

    get '/accounts/login' => 'accounts/sessions#new' # Keep previous URL working

    get '/accounts/sign_in/otp' => 'accounts/otp/sessions#new'
    post '/accounts/sign_in/otp' => 'accounts/otp/sessions#create'
    get '/accounts/sign_in/recovery_code' => 'accounts/recovery_code/sessions#new'
    post '/accounts/sign_in/recovery_code' => 'accounts/recovery_code/sessions#create'
  end

  devise_for :accounts, controllers: {
    sessions: 'accounts/sessions'
  }

  get "/accounts/sign_up", to: redirect('https://arpnetworks.com') # Keep previous URL working but redirect to the main site
  get "/accounts/new", to: redirect('https://arpnetworks.com') # Keep previous URL working but redirect to the main site

  resources :accounts, except: [:new, :create] do

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
    resources :ssh_keys
    resource :security, controller: :security, only: [:show]
    resource :password_change, controller: :password_change, only: [:create, :show]
    resource :two_factor_authentication, only: %i[create destroy]
    namespace :two_factor_authentication do
      resources :recovery_codes, only: [:create, :index]
      resource :confirmation, only: [:new, :create, :show]
    end
  end

  get '/noVNC/console', controller: 'virtual_machines', action: 'console'

  get '/dashboard', controller: 'my_account', action: 'dashboard', as: 'dashboard'

  # For New Service Configurator
  get '/provisioning/ip_address', controller: 'accounts', action: 'ip_address_inventory'

  namespace :admin do
    resources :accounts do
      collection do
        get 'suspended'
      end
    end

    resources :invoices
    resources :services do
      member do
        post 'push_to_stripe'
      end
    end
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
    resources :stripe_events do
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
  get 'admin/whoami',  controller: 'admin/head_quarters', action: 'whoami'

  # Reports
  get 'admin/reports/services', controller: 'admin/reports', action: 'services'

  namespace :api do
    namespace :v1 do
      namespace :internal do
        # VMs
        put 'virtual_machines/:uuid/status/:status', controller: 'virtual_machines',
                                                     action: 'status'
        put 'virtual_machines/statuses',             controller: 'virtual_machines',
                                                     action: 'statuses'
        post 'virtual_machines/phone_home/:uuid',    controller: 'virtual_machines',
                                                     action: 'phone_home'
        # Provisioning
        get 'provisioning/:mac_address/config.tar.gz', controller: 'provisioning',
                                                       action: 'config'

        # Jobs
        put 'jobs/:id/event/:event',       controller: 'jobs',  action: 'event'
        put 'jobs/:id/event/:event/:args', controller: 'jobs',  action: 'event'

        # Legacy
        post 'console_logins',            controller: 'utils', action: 'console_logins'
        get  'console_passwd_file',       controller: 'utils', action: 'console_passwd_file'
        get  'console_passwd_file/:host', controller: 'utils', action: 'console_passwd_file'
        get  'redis/ping',                controller: 'utils', action: 'redis_ping'

        # Other
        get 'jobs/health', controller: 'utils', action: 'job_queue_health'
      end

      namespace :stripe do
        post 'webhook'
      end
    end
  end

  if Rails.env.test?
    namespace :test do
      resource :session, only: %i[create show]
    end
  end

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
