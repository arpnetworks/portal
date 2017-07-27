class Pool < ActiveRecord::Base
  has_many :virtual_machines

  def display_name
    "#{name} (#{pool_type})"
  end
end
