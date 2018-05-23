require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../my_spec_helper')

describe "/services/show.erb" do
  before(:each) do
    assigns[:service] = stub_model(Service)
    assigns[:service].service_code = stub_model(ServiceCode)
    assigns[:services] = [
      stub_model(Service),
      stub_model(Service)
    ]
    assigns[:description] = ''
    assigns[:resources] = []

    @resources = [
      stub_model(Resource),
      stub_model(Resource),
    ]

    assigns[:account] = stub_model(Account)
  end

  context "description is empty" do
    it "should display 'No further details'" do
      assigns[:description] = ''
      render "/services/show.erb"
      response.should have_tag('td', 'No further details')
    end
  
    it "should not display 'No further details' if resources exist" do
      @service = stub_model(Service)
      @service.service_code = stub_model(ServiceCode)
      @service.stub!(:resources).and_return(@resources)
      assigns[:description] = ''
      assigns[:service] = @service
      assigns[:resources] = @resources
  
      render "/services/show.erb"
      response.should_not have_tag('td', /No further details/)
    end
  end
end

