class Host < ActiveRecord::Base
  belongs_to :location

  def display_name
    hostname + " (#{location.code})"
  end
end
