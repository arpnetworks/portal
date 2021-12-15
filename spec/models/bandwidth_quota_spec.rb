require 'rails_helper'

context 'BandwidthQuota class' do
  before do
    @bandwidth_quota = BandwidthQuota.new
  end

  context 'graph_url()' do
    specify 'should be direct link to graph when cacti_local_graph_id not nil' do
      local_graph_id = 1000
      @bandwidth_quota.cacti_local_graph_id = local_graph_id
      expect(@bandwidth_quota.graph_url).to eq \
        "https://graphs.arpnetworks.com/cacti/graph.php?local_graph_id=#{local_graph_id}&rra_id=all"
    end
    specify 'should be generic link to graph when cacti_local_graph_id nil' do
      @bandwidth_quota.cacti_local_graph_id = nil
      expect(@bandwidth_quota.graph_url).to eq \
        'https://graphs.arpnetworks.com/cacti'
    end
    specify 'should be generic link to graph when cacti_local_graph_id is empty' do
      @bandwidth_quota.cacti_local_graph_id = ''
      expect(@bandwidth_quota.graph_url).to eq \
        'https://graphs.arpnetworks.com/cacti'
    end
  end
end
