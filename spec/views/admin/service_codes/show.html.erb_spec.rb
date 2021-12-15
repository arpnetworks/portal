require 'rails_helper'

describe '/admin/service_codes/show.html.erb' do
  before(:each) do
    assign(:service_codes, [
             stub_model(ServiceCode),
             stub_model(ServiceCode)
           ])
  end
end
