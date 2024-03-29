require 'rails_helper'

describe '/admin/service_codes/new.html.erb' do
  include RSpecHtmlMatchers

  before(:each) do
    assign(:service_code, build(:service_code))
  end

  it 'should render new form' do
    render template: '/admin/service_codes/new.html.erb'

    expect(response).to have_tag("form[action='%s'][method=post]" % admin_service_codes_path)
  end
end
