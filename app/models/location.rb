class Location < ApplicationRecord
  validates_uniqueness_of :code

  def display_name
    "#{name} (#{code})"
  end

  def display_name_simple
    name
  end
end
