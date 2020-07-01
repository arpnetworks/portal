class BackupQuota < ApplicationRecord
  self.table_name = 'backup_quotas'

  include Resourceable

  validates_uniqueness_of :username, scope: :server
end
