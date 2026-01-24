class BandwidthQuota < ApplicationRecord
  self.table_name = 'bandwidth_quotas'

  include Resourceable

  validates_numericality_of :commit
  validates_numericality_of :cacti_local_graph_id, allow_nil: true
  validates_format_of       :commit_unit, with: /\A(Mbps|GB)\Z/

  def graph_url
    domain = graph_domain
    use_new_cacti = (domain == "cacti.arpnetworks.com")

    if cacti_local_graph_id.to_s.empty?
      if use_new_cacti
        "https://#{domain}/"
      else
        "https://#{domain}/cacti"
      end
    else
      if use_new_cacti
        "https://#{domain}/graph.php?local_graph_id=#{cacti_local_graph_id}&rra_id=all"
      else
        "https://#{domain}/cacti/graph.php?local_graph_id=#{cacti_local_graph_id}&rra_id=all"
      end
    end
  end

  private

  def graph_domain
    # If this record has been migrated to the new Cacti server, use new domain
    if cacti_migrated_at.present?
      "cacti.arpnetworks.com"
    else
      # Otherwise, use old Cacti server for pre-migration records
      # New records created after cutoff also use new server
      cutoff_date = Date.new(2026, 1, 14)

      if resource&.service&.created_at && resource.service.created_at.to_date > cutoff_date
        "cacti.arpnetworks.com"
      else
        "graphs.arpnetworks.com"
      end
    end
  end
end
