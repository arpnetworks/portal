class Export < ApplicationRecord
  validates :exported_at, presence: true

  def self.record_export!(record_type)
    last = Export.where(record_type: record_type).order('exported_at asc').last

    if last.nil?
      last = DateTime.parse("1969-12-31T00:00:00+00:00")
    else
      last = last.exported_at
    end

    started_at = Time.now

    num_of_records = yield(last)

    if num_of_records && record_type
      create(exported_at: started_at, records: num_of_records, record_type: record_type)
    end
  end
end
