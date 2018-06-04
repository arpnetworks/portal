class BgpSession < ActiveRecord::Base
  include Resourceable

  has_many :prefixes, :class_name => 'BgpSessionsPrefix', :dependent => :destroy

  scope :active,   -> { where(deleted_at: nil) }
  scope :inactive, -> { where("deleted_at IS NOT NULL") }

  after_create  :mail_irr_as_set
  after_destroy :mail_irr_as_set

  def display_service_with_account
     account.display_account_name + ": ASN " + asn.to_s + " (#{session_type_info})"
  end

  def session_type_info
    peer_ip_address_a =~ /:/ ? 'v6' : 'v4'
  end

  def as_set
    my_as_set = read_attribute :as_set

    my_as_set || ("AS" + asn.to_s)
  end

  def mail_irr_as_set
    Mailer.irr_as_set(all_as_sets).deliver_now
  end

  protected

  def all_as_sets
    BgpSession.active.map { |o| o.as_set }.uniq
  end
end
