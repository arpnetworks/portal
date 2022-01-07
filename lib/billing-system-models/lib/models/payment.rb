class Payment < ActiveRecord::Base
  belongs_to :account
  has_many :invoices_payments
  has_many :invoices, :through => :invoices_payments

  validates_presence_of :amount
  validates_numericality_of :amount
end
