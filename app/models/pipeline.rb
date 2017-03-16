# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class PipelinesRequestType < ActiveRecord::Base
  belongs_to :pipeline, inverse_of: :pipelines_request_types
  belongs_to :request_type, inverse_of: :pipelines_request_types

  validates_uniqueness_of :request_type_id, scope: :pipeline_id
  validates_presence_of :request_type, :pipeline
end

class Pipeline < ActiveRecord::Base
  include ::ModelExtensions::Pipeline
  include SequencingQcPipeline
  include Uuid::Uuidable
  include Pipeline::InboxUngrouped
  include Pipeline::BatchValidation
  include SharedBehaviour::Named

  class_attribute :batch_worksheet
  self.batch_worksheet = 'detailed_worksheet'

  INBOX_PARTIAL               = 'default_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = false # Override this in subclasses if you want to display action links for released batches

  self.inheritance_column = 'sti_type'

  delegate :item_limit, :has_batch_limit?, to: :workflow
  validates_presence_of :workflow

  belongs_to :location
  belongs_to :control_request_type, class_name: 'RequestType'
  belongs_to :next_pipeline,     class_name: 'Pipeline'
  belongs_to :previous_pipeline, class_name: 'Pipeline'

  has_one :workflow, class_name: 'LabInterface::Workflow', inverse_of: :pipeline

  has_many :controls
  has_many :pipeline_request_information_types
  has_many :request_information_types, through: :pipeline_request_information_types
  has_many :tasks, through: :workflows
  has_many :pipelines_request_types, inverse_of: :pipeline
  has_many :request_types, through: :pipelines_request_types, validate: false
  has_many :requests, through: :request_types, extend: [Pipeline::InboxExtensions, Pipeline::RequestsInStorage]
  has_many :batches do
    def build(attributes = nil)
      attributes ||= {}
      attributes[:item_limit] = proxy_association.owner.workflow.item_limit
      super(attributes)
    end
  end

  validates_presence_of :request_types
  validates_presence_of :name
  validates_uniqueness_of :name, on: :create, message: 'name already in use'

  scope :externally_managed, -> { where(externally_managed: true) }
  scope :internally_managed, -> { where(externally_managed: false) }
  scope :active,             -> { where(active: true) }
  scope :inactive,           -> { where(active: false) }

  scope :for_request_type, ->(rt) {
    joins(:pipelines_request_types)
    .where(pipelines_request_types: { request_type_id: rt })
  }

  def request_types_including_controls
    [control_request_type].compact + request_types
  end

  def custom_inbox_actions
    []
  end

  def inbox_partial
    INBOX_PARTIAL
  end

  def inbox_eager_loading
    :loaded_for_inbox_display
  end

  def display_next_pipeline?
    false
  end

  def requires_position?
    true
  end

  # This needs to be re-done a better way
  def qc?
    false
  end

  def library_creation?
    false
  end

  def genotyping?
    false
  end

  def sequencing?
    false
  end

  def is_read_length_consistent_for_batch?(_batch)
    true
  end

  # This is the old behaviour for every other pipeline.
  def detach_request_from_batch(batch, request)
    request.return_for_inbox!
    update_detached_request(batch, request)
    request.save!
  end

  def update_detached_request(_batch, request)
    request.remove_unused_assets
  end

  def grouped_requests(show_held_requests = true)
    inbox_scope_on(requests.inputs(show_held_requests).unbatched.send(inbox_eager_loading)).for_group_by(grouping_attributes)
  end

  def inbox_scope_on(inbox_scope)
    custom_inbox_actions.inject(inbox_scope) { |context, action| context.send(action) }
  end
  private :inbox_scope_on

  def grouping_function(option = {})
    return ->(r) { [r.container_id] } if option[:group_by_holder_only]

    lambda do |request|
      [].tap do |group_key|
        group_key << request.container_id  if group_by_parent?
        group_key << request.submission_id if group_by_submission?
      end
    end
  end
  private :grouping_function

  def grouping_attributes
    {}.tap do |group_key|
      group_key[:hl] = :container_id if group_by_parent?
      group_key[:requests] = :submission_id if group_by_submission?
    end
  end
  private :grouping_attributes

  # to overwrite by subpipeline if needed
  def group_requests(requests, option = {})
    requests.group_requests(option).all.group_by(&grouping_function(option))
  end

  def finish_batch(batch, user)
    batch.complete!(user)
  end
  deprecate finish_batch: 'use batch#complete! instead'

  def post_finish_batch(batch, user)
  end

  def completed_request_as_part_of_release_batch(request)
    if library_creation?
      unless request.failed?
        EventSender.send_pass_event(request.id, '', "Passed #{name}.", id)
        EventSender.send_request_update(request.id, 'complete', "Completed pipeline: #{name}")
      end
    else
      EventSender.send_request_update(request.id, 'complete', "Completed pipeline: #{name}")
    end
  end

  def release_batch(batch, user)
    batch.release!(user)
  end
  deprecate release_batch: 'use batch#release! instead'

  def on_start_batch(batch, user)
    # Do nothing
  end

  def post_release_batch(batch, user)
    # Do Nothing
  end

  def has_controls?
    controls.empty? ? false : true
  end

  def pulldown?
    false
  end

  def purpose_information?
    true
  end

  def prints_a_worksheet_per_task?
    false
  end

  def grouping_parser
    GrouperForPipeline.new(self)
  end
  private :grouping_parser

  def selected_values_from(browser_options)
    browser_options.select { |_, v| v == '1' }
  end
  private :selected_values_from

  def extract_requests_from_input_params(params)
    if (request_ids = params['request']).present?
      requests.inputs(true).order(:id).find(selected_values_from(request_ids).map(&:first))
    elsif (selected_groups = params['request_group']).present?
      grouping_parser.all(selected_values_from(selected_groups))
    else
      raise StandardError, 'Unknown manner in which to extract requests!'
    end
  end

  def max_number_of_groups
    self[:max_number_of_groups] || 0
  end

  def valid_number_of_checked_request_groups?(params = {})
    return true if max_number_of_groups.zero?
    return true if (selected_groups = params['request_group']).blank?
    grouping_parser.count(selected_values_from(selected_groups)) <= max_number_of_groups
  end

  def all_requests_from_submissions_selected?(_request_ids)
    true
  end

  def can_create_stock_assets?
    false
  end

  def request_actions
    [:fail]
  end

  def allow_tag_collision_on_tagging_task?
    true
  end

  def robot_verified!(batch)
    # Do nothing!
  end
end
