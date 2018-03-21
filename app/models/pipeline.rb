# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class PipelinesRequestType < ApplicationRecord
  belongs_to :pipeline, inverse_of: :pipelines_request_types
  belongs_to :request_type, inverse_of: :pipelines_request_types

  validates_uniqueness_of :request_type_id, scope: :pipeline_id
  validates_presence_of :request_type, :pipeline
end

class Pipeline < ApplicationRecord
  include Uuid::Uuidable
  include Pipeline::InboxUngrouped
  include Pipeline::BatchValidation
  include SharedBehaviour::Named

  ALWAYS_SHOW_RELEASE_ACTIONS = false # Override this in subclasses if you want to display action links for released batches

  # Rails class attributes
  self.inheritance_column = 'sti_type'

  # Custom class attributes
  class_attribute :batch_worksheet, :display_next_pipeline, :requires_position,
                  :inbox_partial, :library_creation, :pulldown, :prints_a_worksheet_per_task,
                  :genotyping, :sequencing, :purpose_information, :can_create_stock_assets,
                  :inbox_eager_loading

  # Pipeline defaults
  self.batch_worksheet = 'detailed_worksheet'
  self.display_next_pipeline = false
  self.requires_position = true
  self.inbox_partial = 'default_inbox'
  self.library_creation = false
  self.pulldown = false
  self.prints_a_worksheet_per_task = false
  self.genotyping = false
  self.sequencing = false
  self.purpose_information = true
  self.can_create_stock_assets = false
  self.inbox_eager_loading = :loaded_for_inbox_display

  delegate :item_limit, :batch_limit?, to: :workflow

  belongs_to :control_request_type, class_name: 'RequestType'
  belongs_to :next_pipeline,     class_name: 'Pipeline'
  belongs_to :previous_pipeline, class_name: 'Pipeline'

  has_one :workflow, class_name: 'Workflow', inverse_of: :pipeline, required: true

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

  validates_presence_of :name, :request_types
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

  def extract_requests_from_input_params(params)
    if (request_ids = params['request']).present?
      requests.inputs(true).order(:id).find(selected_values_from(request_ids).map(&:first))
    elsif (selected_groups = params['request_group']).present?
      grouping_parser.all(selected_values_from(selected_groups))
    else
      raise StandardError, 'Unknown manner in which to extract requests!'
    end
  end

  def all_requests_from_submissions_selected?(_request_ids)
    true
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

  def need_target_assets_on_requests?
    asset_type.present? && request_types.needing_target_asset.exists?
  end

  private

  def inbox_scope_on(inbox_scope)
    custom_inbox_actions.inject(inbox_scope) { |context, action| context.send(action) }
  end

  def grouping_function(option = {})
    return ->(r) { [r.container_id] } if option[:group_by_holder_only]

    lambda do |request|
      [].tap do |group_key|
        group_key << request.container_id  if group_by_parent?
        group_key << request.submission_id if group_by_submission?
      end
    end
  end

  def grouping_attributes
    {}.tap do |group_key|
      group_key[:hl] = :container_id if group_by_parent?
      group_key[:requests] = :submission_id if group_by_submission?
    end
  end

  def grouping_parser
    GrouperForPipeline.new(self)
  end

  def selected_values_from(browser_options)
    browser_options.select { |_, v| v == '1' }
  end
end
