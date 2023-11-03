# frozen_string_literal: true
# Place to put Illumina QC code to be refactored
module SequencingQcBatch
  # NOTE: Be careful that the length of these do not exceed 25 characters, otherwise you will have to alter the
  # batches.qc_state field in the DB to accommodate.  FYI, 25 characters is:
  #  <----------------------->
  VALID_QC_STATES = %w[qc_pending qc_submitted qc_manual qc_manual_in_progress qc_completed].freeze

  def self.included(base)
    base.instance_eval do
      # TODO[xxx]: Isn't qc_state supposed to be initialised to 'qc_pending' rather than blank?
      validates_inclusion_of :qc_state, in: VALID_QC_STATES, allow_blank: true

      belongs_to :qc_pipeline, class_name: 'Pipeline'
      before_create :qc_pipeline_update
    end
  end

  #--
  # Batches have, in addition to the State Machine "state", two additional states: qc_state and production_state
  # qc_state is used to track QC process in pipelines and when the QC process is triggered from NPG and when it ends
  # production_state allows a whole batch, and its items, to fail or pass regardless of the QC state.
  # The last State Machine state that a batch can reach is "released"
  # A batch cannot be started once it fails or released
  # QC State ["qc_pending", "qc_manual", "qc_manual_in_progress","qc_completed"]
  #++

  # Returns qc_states used
  def qc_states
    VALID_QC_STATES
  end

  def qc_previous_state!(current_user)
    previous_state = qc_previous_state
    if previous_state
      lab_events.create(
        description: 'QC Rollback',
        message: "Manual QC moved from #{qc_state} to #{previous_state}",
        user_id: current_user.id
      )
      self.qc_state = previous_state
    end
    self.state = 'started'
    save
  end

  def self.adjacent_state_helper(direction, offset, delimiter) # rubocop:todo Metrics/AbcSize
    define_method(:"qc_#{direction}_state") do
      unless qc_states.include?(qc_state.to_s)
        raise StandardError, "Current QC state appears to be invalid: '#{qc_state}'"
      end
      return nil if qc_state.to_s == qc_states.send(delimiter)

      qc_states[qc_states.index(qc_state.to_s) + offset]
    end
  end

  # Sets up qc_next_state and qc_previous_state so that they move in the appropriate direction to find their
  # appropriate state, and are limited by the last or first states (respectively).
  adjacent_state_helper(:next, +1, :last)
  adjacent_state_helper(:previous, -1, :first)

  def self.state_transition_helper(name)
    # TODO[xxx]: Really we should restrict the state transitions
    define_method(:"qc_#{name}") do
      # Maintaining legacy behaviour here as not sure if it was intentional.
      # Allows QC decisions to be made on invalid assets.
      update_attribute(:qc_state, qc_next_state) unless qc_next_state.nil? # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Define the various state transition helpers ...
  state_transition_helper(:submitted)
  state_transition_helper(:criteria_received)
  state_transition_helper(:complete)

  def processing_in_manual_qc?
    %w[qc_manual_in_progress qc_manual].include?(qc_state)
  end

  def qc_manual_in_progress
    self.qc_state = 'qc_manual_in_progress'
    save
  end

  private

  def qc_pipeline_update
    self.qc_pipeline = Pipeline.find_by(name: 'quality control')
    self.qc_state = 'qc_pending'
  end
end
