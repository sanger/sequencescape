module SampleManifest::Statemachine
  def self.extended(base)
    base.class_eval do

      configure_state_machine
    end
  end

  def configure_state_machine
    state_machine :state, :initial => :pending do
      # State Machine events
      event :start do
        transition :to => :processing, :from => [:pending, :failed, :completed, :processing]
      end

      event :finished do
        transition :to => :completed, :from => [:processing]
      end

      event :fail do
        transition :to => :failed, :from => [:processing]
      end
    end

  end 
  private :configure_state_machine
  
end
