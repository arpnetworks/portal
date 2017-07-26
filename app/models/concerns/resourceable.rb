module Resourceable
  def self.included(base)
    base.module_eval do
      has_one :resource, :as => :assignable, :dependent => :destroy
    
      include InstanceMethods
    end
  end

  module InstanceMethods
    def service_id=(sid)
      @service_id = sid
    end

    def service_id
      if new_record?
        @service_id.to_i
      else
        resource && resource.service && resource.service.id
      end
    end

    def account
      resource && resource.service && resource.service.account
    end

    protected

    def after_create
      super

      # If a service ID is defined, assign the resource to that service
      if @service_id
        create_service_assignment(@service_id)
      end
    end

    def after_update
      super

      # If a service ID is defined, assign the resource to that service
      if @service_id
        if resource 
          if resource.service.id != @service_id
            update_service_assignment(@service_id)
          end
        else
          create_service_assignment(@service_id)
        end
      end
    end

    def create_service_assignment(service_id)
      # Create a new resource for the service to which this resource will be assigned
      @service  = Service.find(service_id)
      @resource = @service.resources.new

      # Assign resource
      @resource.assignable = self
      @resource.save

      # Reload so our new associations take effect
      reload
    end

    def update_service_assignment(service_id)
      resource.service = Service.find(service_id)
      resource.save
      reload
    end
  end
end
