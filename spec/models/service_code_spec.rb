require File.dirname(__FILE__) + '/../rails_helper'

describe ServiceCode do
  specify "should count two ServiceCodes" do
    create :service_code
    create :service_code

    expect(ServiceCode.count).to eq 2
  end
end
