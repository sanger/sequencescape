module Batch::StateMachineBehaviour
  def self.included(base)
    base.class_eval do
      aasm_column :state
      aasm_initial_state :pending
      aasm_state :pending
      aasm_state :started, :enter => :start_requests
      aasm_state :completed
      aasm_state :released

      # State Machine events
      aasm_event :start do
        transitions :to => :started, :from => [:pending, :started, :completed, :released]
      end

      aasm_event :complete do
        transitions :to => :completed, :from => [:started, :pending, :completed]
      end

      aasm_event :release do
        transitions :to => :released, :from => [:completed, :started, :pending, :released]
      end

      # Some named scopes needed for finding the batches in a particular state
      named_scope :pending,   :conditions => {:state => "pending"}
      named_scope :started,   :conditions => {:state => "started"}
      named_scope :completed, :conditions => {:state => "completed"}
      named_scope :released,  :conditions => {:state => "released"}
      named_scope :failed,    :conditions => {:production_state => "fail"}

      # We override the behaviour of a couple of events because they require user details.
      alias_method_chain(:start!, :user)
      alias_method_chain(:complete!, :user)
      alias_method_chain(:release!, :user)
    end
  end

  def finished?
    completed? or released?
  end

  def start_with_user!(user)
    start_without_user!
  end

  def complete_with_user!(user)
    complete_without_user! unless released?
    create_complete_batch_event_for(user)
    pipeline.post_finish_batch(self, user)
  end

  def create_complete_batch_event_for(user)
    lab_events.create!(:batch => self, :user => user, :description => 'Complete').tap do |event|
      event.add_descriptor Descriptor.new(:name => 'pipeline_id', :value => pipeline.id)
      event.add_descriptor Descriptor.new(:name => 'pipeline',    :value => pipeline.name)
      event.save!
    end
  end
  private :create_complete_batch_event_for

  def release_with_user!(user)
    requests.each { |request| pipeline.completed_request_as_part_of_release_batch(request) }
    release_without_user!
    create_release_batch_event_for(user)
    pipeline.post_release_batch(self, user)
  end

  def create_release_batch_event_for(user)
    lab_events.create!(:batch => self, :user => user, :description => 'Released').tap do |event|
      event.add_descriptor Descriptor.new(:name => 'workflow_id', :value => workflow.id)
      event.add_descriptor Descriptor.new(:name => 'workflow',    :value => "Released from #{workflow.name}")
      event.add_descriptor Descriptor.new(:name => 'task',        :value => workflow.name)
      event.add_descriptor Descriptor.new(:name => 'Released',    :value => workflow.name)
      event.save!
    end
  end
  private :create_release_batch_event_for
end
