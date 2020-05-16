require File.dirname(__FILE__) + '/../../rails_helper'

describe '/services/show.erb' do
  include RSpecHtmlMatchers

  context 'description is empty' do
    before do
      ip_block = build :ip_block do |ipb|
        ipb.notes = ''
      end
      assign(:ip_blocks, [ip_block])
    end

    it "should not display 'Additional' section" do
      render '/ip_blocks/table_data.erb'
      expect(response).to_not have_tag('td.th-minor', text: /Additional/)
    end
  end

  context 'description is not empty' do
    before do
      ip_block = build :ip_block do |ipb|
        ipb.notes = 'lkjsdf'
      end
      assign(:ip_blocks, [ip_block])
    end

    it "should not display 'Additional' section" do
      render '/ip_blocks/table_data.erb'
      expect(response).to have_tag('td.th-minor', text: /Additional/)
    end
  end
end
