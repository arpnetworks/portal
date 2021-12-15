module AutoloadAllFixtures
  extend ActiveSupport::Concern

  included do
    fixtures :all
  end
end
