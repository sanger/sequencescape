# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
# Place to put Illumina QC code to be refactored
module SequencingQcBatch
  # NOTE: Be careful that the length of these do not exceed 25 characters, otherwise you will have to alter the
  # batches.qc_state field in the DB to accommodate.  FYI, 25 characters is:
  #  <----------------------->
  VALID_QC_STATES = %w(
qc_pending
qc_submitted
qc_manual
qc_manual_in_progress
qc_completed
)

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
  # qc_production allows a whole batch, and its items, to fail or pass regardless of the QC state.
  # The last State Machine state that a batch can reach is "released"
  # A batch cannot be started once it fails or released
  # QC State ["qc_pending", "qc_manual", "qc_manual_in_progress","qc_completed"]
  #++

  # View based check to display batches with results
  def show_in_manual_qc?
    if assets_qc_tasks_results.uniq.size > 1
      answer = false
    else
      answer = true
    end
    answer
  end

  # Cron job specific checker
  def migrate_to_manual_qc?
    if assets_qc_tasks_results.include?(true)
      answer = true
    else
      answer = false
    end
    answer
  end

  # Returns qc_states used
  def qc_states
    VALID_QC_STATES
  end

  def qc_previous_state!(current_user)
    previous_state = qc_previous_state
    if previous_state
      lab_events.create(description: 'QC Rollback', message: "Manual QC moved from #{qc_state} to #{previous_state}", user_id: current_user.id)
      self.qc_state = previous_state
    end
    self.state = 'started'
    save
  end

  def self.adjacent_state_helper(direction, offset, delimiter)
    define_method(:"qc_#{ direction }_state") do
      raise StandardError, "Current QC state appears to be invalid: '#{qc_state}'" unless qc_states.include?(qc_state.to_s)
      return nil if qc_state.to_s == qc_states.send(delimiter)
      return qc_states[qc_states.index(qc_state.to_s) + offset]
    end
  end

  # Sets up qc_next_state and qc_previous_state so that they move in the appropriate direction to find their
  # appropriate state, and are limited by the last or first states (respectively).
  adjacent_state_helper(:next,     +1, :last)
  adjacent_state_helper(:previous, -1, :first)

  def self.state_transition_helper(name)
    # TODO[xxx]: Really we should restrict the state transitions
    define_method(:"qc_#{ name }") do
      update_attribute(:qc_state, qc_next_state) unless qc_next_state.nil?
    end
  end

  # Define the various state transition helpers ...
  state_transition_helper(:submitted)
  state_transition_helper(:criteria_received)
  state_transition_helper(:complete)

  def processing_in_manual_qc?
    ['qc_manual_in_progress', 'qc_manual'].include?(qc_state)
  end

  def qc_pipeline_workflow_id
    pipeline = Pipeline.find_by!(name: 'quality control', automated: true)
    pipeline.workflow.id
  end

  def qc_ready_for_manual
    ActiveRecord::Base.transaction do
      p = Pipeline.find(qc_pipeline_id)
      update_attributes!(qc_pipeline_id: p.next_pipeline_id, qc_state: 'qc_manual')
    end
  end

  def qc_manual_in_progress
    self.qc_state = 'qc_manual_in_progress'
    save
  end

  def qc_pipeline_update
    self.qc_pipeline = Pipeline.find_by(name: 'quality control', automated: true)
    self.qc_state    = 'qc_pending'
  end
  private :qc_pipeline_update

  # POST /batches/submit_to_qc_queue/:id.xml
  def submit_to_qc_queue
    logger.debug "Batch #{id} attempting to be added to QC queue. State is #{qc_state}"
    # Get QC workflow and its tasks
    workflow = LabInterface::Workflow.includes(:tasks).find_by!(name: 'quality control')
    tasks    = workflow.tasks
    if qc_state == 'qc_pending'
      # Submit requests for all tasks in the workflow
      tasks.each do |task|
        # Constructing the XML file to use in sending the request
        h_doc = {}
        batch_requests.each do |b_request|
          h_doc["lane_#{b_request.position}"] = b_request.id
        end
        h_doc['task_id'] = task.id
        h_doc['batch'] = id
        h_doc['keys'] = {}
        task.descriptors.each do |t|
          h_doc['keys'][(t.key).to_s] = t.value
        end
        doc = h_doc.to_xml(root: 'criteria', skip_types: true)
        # A *Hacky* solution to get the XML readable for Chainlink
        doc = doc.to_s.tr!('-', '_').gsub!('UTF_8', 'UTF-8')
        # logger.debug doc
        # Publishing the request to AMQ
        publish :qc_requests, doc
      end
      qc_submitted
      return true
    else
      return false
    end
  end

  # Format qc_info on batch for JSON
  def formatted_batch_qc_details
    batch = self
    temp_variable = {}
    excluding_descriptors = %w(location item batch check jobs run_meta check_key)

    if batch.requests
      batch.requests.each do |item|
        temp_variable[item.to_s] = item
        if batch.qc_pipeline.previous_pipeline
          batch.qc_pipeline.previous_pipeline.workflow.tasks.each do |task|
            item.lab_events.each do |event|
              if event.description == task.name
                grouped_descriptors = {}
                grouped_descriptors[(task.name).to_s] = {}
                event.descriptors.each do |descriptor|
                  unless excluding_descriptors.include? descriptor.name
                    grouped_descriptors[(task.name).to_s][(descriptor.name).to_s] = descriptor.value
                  end
                end
                temp_variable[item.to_s]['qc_data'] = grouped_descriptors
              end
            end
          end
        end
      end
    end
    batch['items'] = temp_variable
    batch
  end

  private

    def assets_qc_tasks_results
      auto_qc_pipeline = Pipeline.firind_by!(name: 'quality control', automated: true)
      qc_workflow = LabInterface::Workflow.find_by pipeline_id: auto_qc_pipeline.id
      qc_tasks = qc_workflow.tasks
      results = []
      qc_tasks.each do |task|
        requests.each do |request|
          if request.asset && request.asset.resource.nil?
            results << request.has_passed(self, task)
          end
        end
      end
      results
    end
end
