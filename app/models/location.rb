class Location < ActiveRecord::Base
  def display_name
    "#{name} (#{code})"
  end
end
