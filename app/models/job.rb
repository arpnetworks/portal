class Job < ActiveRecord::Base
  include AASM

  belongs_to :account

  validates :jid, presence: true
  after_initialize :ensure_jid

  aasm do
    state :waiting, :initial => true

    state :ready
    state :running
    state :done
    state :failed
    state :cancelled

    event :enqueue do
      transitions :from => :waiting, :to => :ready
    end

    event :run do
      transitions :from => :ready, :to => :running
    end

    event :finish, :after => Proc.new { notify_dependent_jobs! } do
      transitions :from => :running, :to => :done,
                  :after => Proc.new { |obj, *args| obj.set_process(*args) }
    end

    event :cancel do
      transitions :from => [:waiting, :ready, :running], :to => :cancelled
    end

    event :fail do
      transitions :from => :running, :to => :failed
    end
  end

  scope :active,   -> { where("aasm_state  = 'ready' or  aasm_state  = 'running'") }
  scope :inactive, -> { where("aasm_state != 'ready' and aasm_state != 'running'") }
  scope :failed,   -> { where("(aasm_state  = 'failed')") }
  scope :recent,   -> { where(["created_at > ?", 48.hours.ago]) }

  after_create do
    if dependent_id.nil?
      enqueue!
    end
  end

  def jid_short
    jid[0..5]
  end

  # TODO: WIP
  def set_process(*args)
    puts "in set_process with args: #{args.join(', ')}"
    puts "This state: #{aasm_state}"
  end

  # TODO: WIP
  def notify_dependent_jobs!(*args)
    puts "in do_afterward with args: #{args.join(', ')}"
    puts "This state: #{aasm_state}"
    puts "retval on this job: #{retval}"
  end

  def retry!
    cl = "Jobs::#{code}".constantize
    cl.new.perform(args)
  end

  protected

  def ensure_jid
    self.jid ||= SecureRandom.hex(12)
  end

  private

  def perform(account, args_json, opts = {})
    code = opts['code'] || self.class.name.demodulize
    desc = opts['description'] || nil

    if account
      account.jobs.create(:code => code, :description => desc, :args => args_json)
    else
      raise "A job must belong to an account"
    end
  end
end
