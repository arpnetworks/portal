class Service < ApplicationRecord
  include Textilizable

  belongs_to :account
  belongs_to :service_code

  has_many :resources,        :dependent => :destroy

  has_many :virtual_machines, :through => :resources, :source => 'assignable', :source_type => 'VirtualMachine'
  has_many :ip_blocks,        :through => :resources, :source => 'assignable', :source_type => 'IpBlock'
  has_many :bandwidth_quotas, :through => :resources, :source => 'assignable', :source_type => 'BandwidthQuota'
  has_many :backup_quotas,    :through => :resources, :source => 'assignable', :source_type => 'BackupQuota'
  has_many :bgp_sessions,     :through => :resources, :source => 'assignable', :source_type => 'BgpSession'

  validates_presence_of :account_id

  scope :active,   -> { where("deleted_at IS NULL and (pending IS NULL or pending = false)") }
  scope :inactive, -> { where("deleted_at IS NOT NULL") }
  scope :pending,  -> { where("pending = true and deleted_at IS NULL") }
  scope :not_pending, -> { where("pending IS NULL or pending = false") }

  textilizable :description

  cattr_reader :per_page
  @@per_page = 10

  def display_service_with_account
    "#{account.display_account_name}: #{title}"
  end

  # Synopsis
  #
  #   Given an array of services, returns the total amount of all services
  #   grouped by billing interval.
  #
  # Arguments
  #
  #   * services: an array of Service's
  #
  # Returns
  #
  #   A hash with keys being billing intervals (integer) and values being the
  #   total amount of services for that interval.
  def self.give_me_totals(services)
    return {} if services.empty?

    hash = {}
    services.each do |service|
      next if service.billing_interval.nil?
      next if service.billing_interval < 1

      if interval = service.billing_interval
        if hash[interval]
          hash[interval] += service.billing_amount
        else
          hash[interval] = service.billing_amount
        end
      end
    end

    hash
  end

  def destroy
    if pending == true
      super

      return
    end

    if !deleted?
      self.update_attribute(:deleted_at, Time.now.utc)

      resources.each do |resource|
        resource.assignable.destroy
      end
    end
  end

  def deleted?
    deleted_at != nil
  end

  # ------------------------------------
  # BEGIN: BillingSystemModels::Sellable
  # ------------------------------------

  include BillingSystemModels::Sellable

  def sellable_code
    service_code.name
  end

  def sellable_description
    title
  end

  def sellable_amount
    billing_amount
  end

  # ------------------------------------
  # END:   BillingSystemModels::Sellable
  # ------------------------------------

end
