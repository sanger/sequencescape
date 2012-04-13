module Submission::Statemachine
  def self.extended(base)
    base.class_eval do
      include InstanceMethods

      configure_state_machine
      alias :editable? building?

      configure_named_scopes
    end
  end

  module InstanceMethods
    # TODO[xxx]: This should be a guard but what the heck ...
    def left_building_state?
      not self.building? or !!@leaving_building_state
    end

    def valid_for_leaving_building_state
      @leaving_building_state = true
      raise ActiveRecord::RecordInvalid, self unless valid?
    ensure
      @leaving_building_state = false
    end
    # TODO[xxx]: ... to here

    def complete_building
      orders(true).all?(&:complete_building)

    end

    def process_submission!
      # Does nothing by default!
    end

    def fail_orders!
      # TODO we need to find a cleaner way release
      # book quota and especially not release them twice
      return if failed?  # don't do it twice
      orders.each(&:unbook_quota_available_for_request_types!)
    end

    def unprocessed?
      UnprocessedStates.include?(state)
    end
  end

  def configure_state_machine
    state_machine :state, :initial => :building do
      event :build do
        transition :from => [ :building ], :to => :pending
      end

      event :process do
        transition :from => [:processing, :failed, :pending], :to => :processing
      end

      event :ready do
        transition :to => :ready, :from => [:processing, :failed]
      end

      event :fail! do
        transition :to => :failed, :from => [:processing, :failed, :pending]
      end

      # after_transition from_state => to_state
      after_transition :building => all,         :do => :valid_for_leaving_building_state
      after_transition       all => :pending,    :do => :complete_building
      after_transition       all => :processing, :do => :process_submission!
      after_transition       all => :failed,     :do => :fail_orders!
    end

  end
  private :configure_state_machine

  UnprocessedStates = ["building", "pending", "processing"]
  def configure_named_scopes
    named_scope :unprocessed, :conditions => {:state => UnprocessedStates}
    named_scope :processed, :conditions => {:state => ["ready", "failed"]}
  end

  private :configure_named_scopes
end
