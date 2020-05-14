require File.dirname(__FILE__) + '/../rails_helper'

describe ServiceCode do
  specify 'should count two ServiceCodes' do
    Service.delete_all
    ServiceCode.delete_all

    create :service_code
    create :service_code

    expect(ServiceCode.count).to eq 2
  end
end
