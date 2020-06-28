require File.dirname(__FILE__) + '/../rails_helper'
require File.dirname(__FILE__) + '/../arp_spec_helper'

RSpec.describe MailerVm, type: :mailer do
  context 'with account and VM' do
    before do
      @vm = build(:virtual_machine)
      @account = build(:account)
      @location = double(:location, display_name_simple: 'Los Angeles')
      allow(@vm).to receive(:account).and_return(@account)
      allow(@vm).to receive(:location).and_return(@location)
    end

    context 'with mailer' do
      before do
        @mailer = MailerVm.setup_complete(@vm)
      end

      describe 'setup_complete' do
        it 'should render the subject' do
          expect(@mailer.subject).to eq 'Server Setup Complete'
        end
      end
    end
  end
end
