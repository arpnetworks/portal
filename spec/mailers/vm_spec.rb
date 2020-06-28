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
      allow(@vm).to receive(:os).and_return("OpenBSD 6.7")
    end

    context 'with mailer' do
      before do
        @mailer = MailerVm.setup_complete(@vm)
      end

      describe 'setup_complete' do
        it 'should render the subject' do
          expect(@mailer.subject).to eq 'Server Setup Complete'
        end

        it 'should render the sender email' do
          expect(@mailer.from).to eql(['support@arpnetworks.com'])
        end

        it 'should render the receiver email' do
          expect(@mailer.to).to eql([@account.email])
        end

        it 'should render OS info' do
          expect(@mailer.body.encoded).to match(@vm.os)
        end

        it 'should render account info' do
          expect(@mailer.body.encoded).to match(@account.display_name)
        end

        it 'should render newsletter link' do
          expect(@mailer.body.encoded).to match('arp.serve.sh/newsletter')
        end
      end
    end
  end
end
