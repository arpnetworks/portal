require File.dirname(__FILE__) + '/../rails_helper'

context Host do
  before do
    @hostnames = %w(vtr1 vtr2 vtr3)

    @hostnames.each do |host|
      create :host, hostname: "#{host}.example.com"
    end
  end

  context "hosts_for_console_passwd_file()" do
    specify "should return array with only hostnames" do
      expect(Host.hosts_for_console_passwd_file.sort).to eq @hostnames.sort
    end
  end
end
