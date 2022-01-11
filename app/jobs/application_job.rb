class ApplicationJob < ActiveJob::Base
  # By default, failed jobs are discarded; by including retry_on, failed
  # jobs will be retried, before bubbling back up to the queueing system
  # (Sidekiq); they don't get kicked back to Sidekiq otherwise
  #
  # But since we don't have visibility into the internals of ActiveJob,
  # only attempt twice, then go back to Sidekiq, where we at least have
  # a dashboard and can check on the jobs
  retry_on StandardError, wait: 3.seconds, attempts: 2

  # Retry anything that was kick backed to Sidekiq
  sidekiq_options retry: 5

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
