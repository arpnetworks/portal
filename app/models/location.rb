class Location < ActiveRecord::Base
  validates_uniqueness_of :code

  def display_name
    "#{name} (#{code})"
  end
end
