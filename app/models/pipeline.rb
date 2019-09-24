# A Pipeline acts to associate {Request requests} with a {Workflow}.
# Visiting a pipeline's page will display an inbox of pending {Batch unbatched}
# requests, and a summary list of ongoing {Batch batches} for that particular
# pipeline. The users are able to generate new batches from the available requests
# and to from there progress a {Batch} through the associated workflow.
# @note Generally speaking we are trying to migrate pipelines out of the Sequencescape
#       core.
class Pipeline < ApplicationRecord
  include Uuid::Uuidable
  include Pipeline::BatchValidation
  include SharedBehaviour::Named

  ALWAYS_SHOW_RELEASE_ACTIONS = false # Override this in subclasses if you want to display action links for released batches

  # Rails class attributes
  self.inheritance_column = 'sti_type'

  # Custom class attributes
  class_attribute :batch_worksheet, :requires_position,
                  :inbox_partial, :library_creation, :pulldown, :prints_a_worksheet_per_task,
                  :genotyping, :sequencing, :purpose_information, :can_create_stock_assets,
                  :inbox_eager_loading, :group_by_submission, :group_by_parent,
                  :generate_target_assets_on_batch_create, :pick_to,
                  :asset_type, :request_sort_order, instance_writer: false

  # Pipeline defaults
  self.batch_worksheet = 'detailed_worksheet'
  self.requires_position = true
  self.inbox_partial = 'default_inbox'
  self.library_creation = false
  self.pulldown = false
  self.prints_a_worksheet_per_task = false
  self.genotyping = false
  self.sequencing = false
  self.purpose_information = true
  self.pick_to = true
  self.can_create_stock_assets = false
  self.inbox_eager_loading = :loaded_for_inbox_display
  self.group_by_submission = false
  self.group_by_parent = false
  self.generate_target_assets_on_batch_create = false
  self.request_sort_order = { id: :desc }.freeze

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
  has_many :inbox, class_name: 'Request', extend: Pipeline::RequestsInStorage

  validates :name, :request_types, presence: true
  validates :name, uniqueness: { on: :create, message: 'name already in use', case_sensitive: false }

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
  end

  # Overridden in group-by parent pipelines to display input plates
  def input_labware(_requests)
    []
  end

  # Overridden in group-by parent pipelines to display output
  def output_labware(_requests)
    []
  end

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
      requests.inputs(true).order(:id).find(selected_keys_from(request_ids))
    elsif (selected_groups = params['request_group']).present?
      grouping_parser.all(selected_keys_from(selected_groups))
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

  def requests_in_inbox(show_held_requests = true)
    apply_includes(
      requests.unbatched
              .pipeline_pending(show_held_requests)
              .with_present_asset
              .order(request_sort_order)
              .send(inbox_eager_loading)
    )
  end

  def request_count_in_inbox(show_held_requests)
    requests.unbatched
            .pipeline_pending(show_held_requests)
            .with_present_asset
            .count
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
