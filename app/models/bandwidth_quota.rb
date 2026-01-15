class BandwidthQuota < ApplicationRecord
  self.table_name = 'bandwidth_quotas'

  include Resourceable

  validates_numericality_of :commit
  validates_numericality_of :cacti_local_graph_id, allow_nil: true
  validates_format_of       :commit_unit, with: /\A(Mbps|GB)\Z/

  def graph_url
    domain = graph_domain

    if cacti_local_graph_id.to_s.empty?
      "https://#{domain}/cacti"
    else
      "https://#{domain}/cacti/graph.php?local_graph_id=#{cacti_local_graph_id}&rra_id=all"
    end
  end

  private

  def graph_domain
    cutoff_date = Date.new(2026, 1, 14)

    if resource&.service&.created_at && resource.service.created_at.to_date > cutoff_date
      "cacti.arpnetworks.com"
    else
      "graphs.arpnetworks.com"
    end
  end
end
