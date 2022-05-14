require 'rails_helper'

context Host do
  before do
    @hostnames = %w[vtr1.example.com vtr2.example.com vtr3.example.com]

    @hostnames.each do |host|
      create :host, hostname: host
    end
  end

  context 'hosts_for_console_passwd_file()' do
    specify 'should return array of hostnames' do
      expect(Host.hosts_for_console_passwd_file.sort).to eq @hostnames.sort
    end
  end

  context 'normalize_host()' do
    context 'without suffix' do
      before :each do
        @host = 'foo'
      end

      it 'should add suffix' do
        expect(Host.normalize_host(@host)).to eq 'foo.arpnetworks.com'
      end
    end

    context 'with suffix' do
      before :each do
        @host = 'foo.arpnetworks.com'
      end

      it 'should leave host unchanged' do
        expect(Host.normalize_host(@host)).to eq 'foo.arpnetworks.com'
      end
    end
  end
end
