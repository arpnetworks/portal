require File.expand_path(File.dirname(__FILE__) + '/../../../rails_helper')

describe '/admin/service_codes/edit.html.erb' do
  include RSpecHtmlMatchers

  before(:each) do
    @service_code = stub_model(ServiceCode)
    assign(:service_code, @service_code)
  end

  it 'should render edit form' do
    render template: '/admin/service_codes/edit', formats: [:html]

    expect(response).to have_tag("form[action='#{admin_service_code_path(@service_code)}'][method=post]")
  end
end
