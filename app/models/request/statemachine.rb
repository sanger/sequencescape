# This is a module containing the standard statemachine for a request that needs it.
# It provides various callbacks that can be hooked in to by the derived classes.
module Request::Statemachine
  def self.included(base)
    base.class_eval do
      ## State machine
      aasm_column :state
      aasm_state :pending
      aasm_state :started,   :enter => :on_started
      aasm_state :failed,    :enter => :on_failed
      aasm_state :passed,    :enter => :on_passed
      aasm_state :cancelled, :enter => :on_cancelled
      aasm_state :blocked,   :enter => :on_blocked
      aasm_state :hold,      :enter => :on_hold
      aasm_initial_state :pending

      # State Machine events
      aasm_event :start do
        transitions :to => :started, :from => [:pending, :started, :hold]
      end

      aasm_event :pass do
        transitions :to => :passed, :from => [:started, :passed, :pending, :failed]
      end

      aasm_event :fail do
        transitions :to => :failed, :from => [:started, :pending, :failed, :passed]
      end

      aasm_event :block do
        transitions :to => :blocked, :from => [:pending]
      end

      aasm_event :unblock do
        transitions :to => :pending, :from => [:blocked]
      end

      aasm_event :detach do
        transitions :to => :pending, :from => [:cancelled, :started, :pending]
      end

      aasm_event :reset do
        transitions :to => :pending, :from => [:started, :pending, :passed, :failed, :hold]
      end

      aasm_event :cancel do
        transitions :to => :cancelled, :from => [:started, :pending, :passed, :failed, :hold]
      end
      @@aliquot_handler=nil
      def self.UpdateRequestInBulk
        Aliquot::BulkCreator.new do |handler|
          @@aliquot_handler = handler
          yield
        end
        @@aliquot_handler = nil
      end
      def self.add_aliquots(asset, aliquots)
        if @@aliquot_handler
          @@aliquot_handler.add(asset, aliquots)
        else
          asset.aliquots << aliquots
        end
        aliquots
      end
    end
  end

  #--
  # These are the callbacks that will be made on entry to a given state.  This allows
  # derived classes to override these and add custom behaviour.  You are advised to call
  # super in any method that you override so that they can be stacked.
  #++

  # On starting a request the aliquots are copied from the source asset to the target 
  # and updated with the project and study information from the request itself.
  def on_started
    add_aliquots(target_asset, asset.aliquots.map do |aliquot|
      aliquot.clone.tap do |clone|
        clone.study   = study   || aliquot.study
        clone.project = project || aliquot.project
      end                                         
    end
    )
  end

  def add_aliquots(*args)
    self.class.add_aliquots(*args)
  end



  def on_failed

  end

  def on_passed

  end

  def on_cancelled

  end

  def on_blocked

  end

  def on_hold

  end
end
