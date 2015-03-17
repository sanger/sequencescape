#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
module SampleManifest::StateMachine
  def self.extended(base)
    base.class_eval do
      include AASM

      configure_state_machine
    end
  end

  def configure_state_machine
    aasm_column :state
    aasm_state :pending
    aasm_state :processing
    aasm_state :failed
    aasm_state :completed
    aasm_initial_state :pending

    # State Machine events
    aasm_event :start do
      transitions :to => :processing, :from => [:pending, :failed, :completed, :processing]
    end

    aasm_event :finished do
      transitions :to => :completed, :from => [:processing]
    end

    aasm_event :fail do
      transitions :to => :failed, :from => [:processing]
    end
  end
  private :configure_state_machine

end
