require File.dirname(__FILE__) + '/../../rails_helper'

describe '/services/show.erb' do
  include RSpecHtmlMatchers

  before(:each) do
    assign(:service, stub_model(Service, service_code: stub_model(ServiceCode)))
    assign(:services, [
             stub_model(Service),
             stub_model(Service)
           ])
    assign(:description, '')
    assign(:resources, [])

    @resources = [
      stub_model(Resource),
      stub_model(Resource)
    ]

    assign(:account, stub_model(Account))
  end

  context 'description is empty' do
    it "should display 'No further details'" do
      assigns[:description] = ''
      assign(:description, '')
      render template: '/services/show.erb'
      expect(response).to have_tag('td', /No further details/)
    end

    it "should not display 'No further details' if resources exist" do
      @service = stub_model(Service,
                            service_code: stub_model(ServiceCode),
                            resources: @resources)
      assign(:description, '')
      assign(:service, @service)
      assign(:resources, @resources)

      render template: '/services/show.erb'
      expect(response).to_not have_tag('td', text: /No further details/)
    end
  end
end
