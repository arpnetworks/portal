class Location < ApplicationRecord
  validates :code, uniqueness: { case_sensitive: false }

  def display_name
    "#{name} (#{code})"
  end

  def display_name_simple
    name
  end
end
