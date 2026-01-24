require 'rails_helper'

context 'BandwidthQuota class' do
  before do
    @bandwidth_quota = BandwidthQuota.new
  end

  context 'graph_url()' do
    context 'when service created before or on 2026-01-14' do
      before do
        service = Service.new(created_at: Date.new(2026, 1, 14))
        resource = Resource.new(service: service)
        allow(@bandwidth_quota).to receive(:resource).and_return(resource)
      end

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

    context 'when service created after 2026-01-14' do
      before do
        service = Service.new(created_at: Date.new(2026, 1, 15))
        resource = Resource.new(service: service)
        allow(@bandwidth_quota).to receive(:resource).and_return(resource)
      end

      specify 'should use cacti.arpnetworks.com for direct link when cacti_local_graph_id not nil' do
        local_graph_id = 1000
        @bandwidth_quota.cacti_local_graph_id = local_graph_id
        expect(@bandwidth_quota.graph_url).to eq \
          "https://cacti.arpnetworks.com/graph.php?local_graph_id=#{local_graph_id}&rra_id=all"
      end

      specify 'should use cacti.arpnetworks.com for generic link when cacti_local_graph_id nil' do
        @bandwidth_quota.cacti_local_graph_id = nil
        expect(@bandwidth_quota.graph_url).to eq \
          'https://cacti.arpnetworks.com/'
      end

      specify 'should use cacti.arpnetworks.com for generic link when cacti_local_graph_id is empty' do
        @bandwidth_quota.cacti_local_graph_id = ''
        expect(@bandwidth_quota.graph_url).to eq \
          'https://cacti.arpnetworks.com/'
      end
    end

    context 'when resource or service is nil' do
      specify 'should default to graphs.arpnetworks.com when resource is nil' do
        @bandwidth_quota.cacti_local_graph_id = 1000
        expect(@bandwidth_quota.graph_url).to eq \
          "https://graphs.arpnetworks.com/cacti/graph.php?local_graph_id=1000&rra_id=all"
      end
    end
  end
end
