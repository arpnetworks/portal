require 'rails_helper'

context ServicesController do
  before do
    @account = create_user!(login: 'user2', create_service: true)
    sign_in @account
    allow(controller).to receive(:current_account).and_return @account
  end

  specify 'should be a ServicesController' do
    expect(controller).to be_an_instance_of(ServicesController)
  end

  context 'index action' do
    specify 'should respond with success' do
      get :index, params: { account_id: @account.id }
      expect(@response).to be_successful
    end
  end

  context 'show action' do
    before do
      @service = @account.services.first
    end

    specify 'should respond with success' do
      get :show, params: { account_id: @account.id, id: @service.id }
      expect(@response).to be_successful
      expect(@response).to render_template('show')
    end

    specify 'should redirect to index when given bad id' do
      get :show, params: { account_id: @account.id, id: 999 }
      expect(@response).to redirect_to(account_services_path(@account.id))
      expect(flash[:error]).to_not be_nil
    end

    specify 'should create a @services array with just this service' do
      get :show, params: { account_id: @account.id, id: @service.id }
      expect(assigns(:services).size).to eq 1
      expect(assigns(:services)).to eq [@service]
    end

    specify 'should set @description from @service.description' do
      get :show, params: { account_id: @account.id, id: @service.id }
      expect(assigns(:description)).to eq @service.description
    end

    specify 'should not show deleted record' do
      @service = create :service, :deleted
      @account.services << @service

      get :show, params: { account_id: @account.id, id: @service.id }
      expect(assigns(:service)).to be_nil
    end

    context 'resource details' do
      specify 'should set @virtual_machines' do
        get :show, params: { account_id: @account.id, id: @service.id }
        expect(assigns(:resources)).to eq @service.resources
      end
    end
  end

  context 'update label action' do
    def do_put(opts = {})
      put :update_label, params: { account_id: @account.id, id: @service.id }.merge(opts)
    end

    before do
      @service = @account.services.first
    end

    specify 'should update the label of service' do
      label = 'foo'
      expect(@service.label).to_not eq label
      do_put(service: { label: label })

      expect(response).to redirect_to(account_service_path(@account.id, @service.id))

      @reloaded_service = Service.find(@service.id)
      expect(@reloaded_service.label).to eq label

      expect(flash[:notice]).to_not be_empty
    end
  end

  context 'confirm' do
    before do
      session['form'] = {}

      allow_any_instance_of(Account).to receive(:beta_features?).and_return(true) # TODO: Remove after beta
      allow(controller).to receive(:check_cc_exists_and_current).and_return(true)
      allow(controller).to receive(:check_account_isnt_blank).and_return(true)
    end

    def do_post(opts = {})
      post :confirm, params: { account_id: @account.id }.merge(opts)
    end

    context 'chosen service is VPS with OS' do
      before do
        @opts = {
          service: 'vps_with_os'
        }
      end

      context 'with valid parameters' do
        before do
          @params = {
            plan: 'small',
            os: 'freebsd-12.1-amd64',
            location: 'lax',
            ipv4: '10.0.0.1',
            ssh_keys: %w[101 304]
          }
          @opts = @opts.merge(@params)
        end

        it 'should save parameters in the form session' do
          do_post(@opts)

          %i[plan os location ipv4 ssh_keys].each do |param|
            expect(session['form'][param.to_s]).to eq @params[param]
          end
        end

        context 'with offloaded billing' do
          before :each do
            allow(@account).to receive(:offload_billing?).and_return true
          end

          it 'should retrieve Stripe subscription' do
            @subs = double(:subscriptions, count: 1)
            expect(Stripe::Subscription).to receive(:list).with(customer: @account.stripe_customer_id)\
                                                          .and_return(@subs)
            do_post(@opts)
          end

          context 'and one subscription' do
            before :each do
              @subs = double(:subscriptions, count: 1)
              allow(Stripe::Subscription).to receive(:list).and_return @subs
            end

            it 'should not create a pro-rated invoice' do
              do_post(@opts)
              expect(@account).to_not receive(:create_pro_rated_invoice!)
            end
          end

          context 'and no subscriptions' do
            before :each do
              @subs = double(:subscriptions, count: 0)
              allow(Stripe::Subscription).to receive(:list).and_return @subs
            end

            it 'should set flag for brand new subscription requirement' do
              do_post(@opts)
              expect(session[:requires_new_subscription]).to eq true
            end
          end
        end
      end

      context 'with invalid parameters' do
        before do
          @opts = @opts.merge({
                                plan: 'small',
                                os: 'freebsd-12.1-amd64',
                                location: 'lax',
                                ipv4: '10.0.0.1'
                              })
        end

        context 'chosen plan is invalid' do
          before do
            @opts = @opts.merge({
                                  plan: 'invalid'
                                })
          end

          it 'should go back to choose plan page' do
            do_post(@opts)
            expect(response).to redirect_to(new_account_service_path(@account.id) + '?service=' + @opts[:service])
          end
        end

        context 'IP has not been chosen' do
          before do
            @opts = @opts.merge({
                                  ipv4: ''
                                })
          end

          it 'should go back to choose plan page' do
            do_post(@opts)
            expect(response).to redirect_to(new_account_service_path(@account.id) + '?service=' + @opts[:service])
          end
        end

        context 'OS has not been chosen' do
          before do
            @opts = @opts.merge({
                                  os: ''
                                })
          end

          it 'should go back to choose plan page' do
            do_post(@opts)
            expect(response).to redirect_to(new_account_service_path(@account.id) + '?service=' + @opts[:service])
          end
        end

        context 'Location has not been chosen' do
          before do
            @opts = @opts.merge({
                                  location: ''
                                })
          end

          it 'should go back to choose plan page' do
            do_post(@opts)
            expect(response).to redirect_to(new_account_service_path(@account.id) + '?service=' + @opts[:service])
          end
        end
      end
    end
  end
end
