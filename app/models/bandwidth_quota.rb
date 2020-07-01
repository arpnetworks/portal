class BandwidthQuota < ApplicationRecord
  self.table_name = 'bandwidth_quotas'

  include Resourceable

  validates_numericality_of :commit
  validates_numericality_of :cacti_local_graph_id, allow_nil: true
  validates_format_of       :commit_unit, with: /\A(Mbps|GB)\Z/

  def graph_url
    if cacti_local_graph_id.to_s.empty?
      "https://graphs.arpnetworks.com/cacti"
    else
      "https://graphs.arpnetworks.com/cacti/graph.php?local_graph_id=#{cacti_local_graph_id}&rra_id=all"
    end
  end
end
