# frozen_string_literal: true
# A Pipeline acts to associate {Request requests} with a {Workflow}.
# Visiting a pipeline's page will display an inbox of pending {Batch unbatched}
# requests, and a summary list of ongoing {Batch batches} for that particular
# pipeline. The users are able to generate new batches from the available requests
# and to from there progress a {Batch} through the associated workflow.
# @note Generally speaking we are trying to migrate pipelines out of the Sequencescape
#       core.
class Pipeline < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include Uuid::Uuidable
  include Pipeline::BatchValidation
  include SharedBehaviour::Named

  # Rails class attributes
  self.inheritance_column = 'sti_type'

  # Custom class attributes
  class_attribute :batch_worksheet,
                  :requires_position,
                  :inbox_partial,
                  :sequencing,
                  :purpose_information,
                  :inbox_eager_loading,
                  :group_by_submission,
                  :group_by_parent,
                  :generate_target_assets_on_batch_create,
                  :asset_type,
                  :request_sort_order,
                  :pick_data,
                  instance_writer: false

  # Pipeline defaults
  self.batch_worksheet = false
  self.requires_position = false
  self.inbox_partial = 'default_inbox'
  self.sequencing = false
  self.purpose_information = true
  self.inbox_eager_loading = :loaded_for_inbox_display
  self.group_by_submission = false
  self.group_by_parent = false
  self.generate_target_assets_on_batch_create = false
  self.request_sort_order = { id: :desc }.freeze
  self.pick_data = false

  delegate :item_limit, :batch_limit?, to: :workflow

  belongs_to :control_request_type, class_name: 'RequestType'

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
  has_many :inbox, class_name: 'Request', extend: Pipeline::RequestsInStorage

  validates :name, :request_types, presence: true
  validates :name, uniqueness: { on: :create, message: 'name already in use', case_sensitive: false }

  scope :externally_managed, -> { where(externally_managed: true) }
  scope :internally_managed, -> { where(externally_managed: false) }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  scope :for_request_type,
        ->(rt) { joins(:pipelines_request_types).where(pipelines_request_types: { request_type_id: rt }) }

  def request_types_including_controls
    [control_request_type].compact + request_types
  end

  def is_read_length_consistent_for_batch?(_batch)
    true
  end

  def is_flowcell_type_consistent_for_batch?(_batch)
    true
  end

  # This is the old behaviour for every other pipeline.
  def detach_request_from_batch(_batch, request)
    request.return_for_inbox!
    request.batch = nil
    request.save!
  end

  # Overridden in group-by parent pipelines to display input plates
  def input_labware(_requests)
    Labware.none
  end

  # Overridden in group-by parent pipelines to display output
  def output_labware(_requests)
    Labware.none
  end

  def post_finish_batch(batch, user); end

  def completed_request_as_part_of_release_batch(request)
    EventSender.send_request_update(request, 'complete', "Completed pipeline: #{name}")
  end

  def on_start_batch(batch, user)
    # Do nothing
  end

  def post_release_batch(batch, user)
    # Do Nothing
  end

  # Extracts the request ids from the selected requests. Overidden in pipleines
  # which group by parent, as requests are grouped together by eg. submission id and labware id
  # and the individual request ids are unavailable
  def extract_requests_from_input_params(params)
    request_ids = params.fetch('request')
    requests.inputs(true).order(:id).find(selected_keys_from(request_ids))
  end

  def all_requests_from_submissions_selected?(_request_ids)
    true
  end

  def request_actions
    [:fail]
  end

  def robot_verified!(batch)
    # Do nothing!
  end

  def requests_in_inbox(show_held_requests = true)
    apply_includes(
      requests
        .unbatched
        .pipeline_pending(show_held_requests)
        .with_present_asset
        .order(request_sort_order)
        .send(inbox_eager_loading)
    )
  end

  def request_count_in_inbox(show_held_requests)
    requests.unbatched.pipeline_pending(show_held_requests).with_present_asset.count
  end

  def pick_information?(_)
    false
  end

  private

  def apply_includes(scope)
    request_information_types.exists? ? scope.include_request_metadata : scope
  end

  def grouping_parser
    GrouperForPipeline.new(self)
  end

  def selected_keys_from(browser_options)
    browser_options.select { |_, v| v == '1' }.keys
  end
end
