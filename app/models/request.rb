# frozen_string_literal: true
require 'aasm'

# A Request represents work which needs to be done, either to fulfil a customers
# needs {CustomerRequest} or for internal reasons {SystemRequest}.
# The progress of a request is tracked through its {Request::Statemachine state machine}.
class Request < ApplicationRecord # rubocop:todo Metrics/ClassLength
  # Include
  include Aliquot::DeprecatedBehaviours::Request
  include Api::RequestIo::Extensions
  include Uuid::Uuidable
  include AASM
  include AASM::Extensions
  include Commentable
  include StandardNamedScopes
  include Request::Statemachine
  include Batch::RequestBehaviour

  # Extend
  extend Request::Statistics
  extend EventfulRecord
  extend ::Metadata

  # Class attributes
  class_attribute :customer_request, :sequencing, :pre_capture_pooled, :library_creation

  self.sequencing = false
  self.per_page = 500
  self.inheritance_column = 'sti_type'
  self.customer_request = false
  self.pre_capture_pooled = false
  self.library_creation = false

  # Associations
  has_many_events
  has_many_lab_events

  has_one :pipeline, through: :batch
  belongs_to :item
  belongs_to :request_type, inverse_of: :requests, optional: false
  belongs_to :user
  belongs_to :order, inverse_of: :requests
  belongs_to :submission, inverse_of: :requests
  belongs_to :submission_pool, foreign_key: :submission_id

  # project is read only so we can set it everywhere
  # but it will be only used in specific and controlled place
  belongs_to :initial_project, class_name: 'Project'

  # same as project with study
  belongs_to :initial_study, class_name: 'Study'
  belongs_to :work_order, optional: true

  # The assets on a request can be treated as a particular class when being used by certain pieces of code.
  # For instance, QC might be performed on a source asset that is a well, in which case we'd like to load it as such.
  belongs_to :target_asset, class_name: 'Receptacle', inverse_of: :requests_as_target, optional: true
  belongs_to :asset, class_name: 'Receptacle', inverse_of: :requests, optional: true
  belongs_to :source_well, class_name: 'Well', foreign_key: :asset_id, optional: true

  has_one :order_role, through: :order
  has_one :_product_line, through: :request_type, source: :product_line

  has_many :failures, as: :failable
  has_many :samples, through: :asset, source: :samples
  has_many :qc_metric_requests
  has_many :qc_metrics, through: :qc_metric_requests
  has_many :asset_studies, through: :asset, source: :studies

  has_many :request_events, -> { order(:current_from) }, inverse_of: :request do
    def date_for_state(state)
      # Annoyingly we get a new scope generated within the class method
      # so can't actually check if we have the events loaded. This optimization
      # improves performance when passing large numbers of requests, as it
      # lets us eager load request events, reducing database hits.
      if loaded?
        reverse.detect { |event| event.to_state == state }.current_from
      else
        super
      end
    end
  end
  has_many :upstream_requests, through: :asset, source: :requests_as_target

  # Related aliquots are those made as a request is being processed.
  # They can be intermediate aliquots, created while a request is being processed, and wont always
  # reflect the final product of a request.
  has_many :related_aliquots, class_name: 'Aliquot', inverse_of: :request

  # Can have many key value pairs of metadata
  has_many :poly_metadata, as: :metadatable, dependent: :destroy

  delegate :flowcell, to: :batch, allow_nil: true
  delegate :for_multiplexing?, to: :request_type

  # Only actively used by poolable requests, but here to help with eager loading
  has_one :pooled_request, dependent: :destroy, class_name: 'PreCapturePool::PooledRequest', inverse_of: :request
  has_one :pre_capture_pool, through: :pooled_request, inverse_of: :pooled_requests

  delegate :position, to: :batch_request

  has_one :target_labware, through: :target_asset, source: :labware
  has_one :source_labware, through: :asset, source: :labware

  convert_labware_to_receptacle_for :asset, :target_asset

  # A request_purpose is a simple means of distinguishing WHY a request was made.
  # cf. RequestType which defines how it will be fulfilled.
  # Both RequestType and Request have a purpose, with the former acting as the default for
  # the latter.
  enum :request_purpose, { standard: 1, internal: 2, qc: 3, control: 4 }

  # Validations
  # On create we perform a full and complete validation.
  validates :request_purpose, presence: true

  broadcast_with_warren

  # Scopes
  scope :for_pipeline,
        ->(pipeline) do
          joins('LEFT JOIN pipelines_request_types prt ON prt.request_type_id=requests.request_type_id').where(
            ['prt.pipeline_id=?', pipeline.id]
          ).readonly(false)
        end

  scope :customer_requests, -> { where(sti_type: [CustomerRequest, *CustomerRequest.descendants].map(&:name)) }

  scope :for_pooling_of,
        ->(plate) do
          submission_ids = plate.all_submission_ids
          add_joins =
            if plate.stock_plate?
              ['INNER JOIN receptacles AS pw ON requests.asset_id=pw.id']
            else
              [
                'INNER JOIN well_links ON well_links.source_well_id=requests.asset_id',
                'INNER JOIN receptacles AS pw ON well_links.target_well_id=pw.id AND well_links.type="stock"'
              ]
            end

          select(
            "uuids.external_id AS pool_id,
              GROUP_CONCAT(DISTINCT pw_location.description ORDER BY pw.map_id ASC SEPARATOR \",\") AS pool_into,
              SUM(requests.state = 'passed') > 0 AS pool_complete,
              MIN(requests.id) AS id,
              MIN(requests.sti_type) AS sti_type,
              MIN(requests.target_asset_id) AS target_asset_id,
              MIN(requests.submission_id) AS submission_id,
              MIN(requests.request_type_id) AS request_type_id"
          )
            .joins(
              add_joins +
                [
                  'INNER JOIN maps AS pw_location ON pw.map_id=pw_location.id',
                  'INNER JOIN uuids ON uuids.resource_id=requests.submission_id AND uuids.resource_type="Submission"'
                ]
            )
            .group('pool_id')
            .where(pw: { labware_id: plate.id }, requests: { submission_id: submission_ids })
            .where.not(requests: { state: 'cancelled' })
        end

  scope :for_pre_cap_grouping_of,
        ->(plate) do
          add_joins =
            if plate.stock_plate?
              ['INNER JOIN receptacles AS pw ON requests.asset_id=pw.id']
            else
              [
                'INNER JOIN well_links ON well_links.source_well_id=requests.asset_id',
                'INNER JOIN receptacles AS pw ON well_links.target_well_id=pw.id AND well_links.type="stock"'
              ]
            end

          select(
            'min(uuids.external_id) AS group_id,
      GROUP_CONCAT(DISTINCT pw_location.description SEPARATOR ",") AS group_into,
      MIN(requests.id) AS id, MIN(requests.submission_id) AS submission_id,
      MIN(requests.request_type_id) AS request_type_id'
          )
            .joins(
              add_joins +
                [
                  'INNER JOIN maps AS pw_location ON pw.map_id = pw_location.id',
                  # rubocop:todo Layout/LineLength
                  'INNER JOIN pre_capture_pool_pooled_requests ON requests.id=pre_capture_pool_pooled_requests.request_id',
                  'INNER JOIN uuids ON uuids.resource_id = pre_capture_pool_pooled_requests.pre_capture_pool_id AND uuids.resource_type="PreCapturePool"'
                  # rubocop:enable Layout/LineLength
                ]
            )
            .group('pre_capture_pool_pooled_requests.pre_capture_pool_id')
            .where(state: %w[started pending])
            .where(pw: { labware_id: plate })
        end

  scope :in_order, ->(order) { where(order_id: order) }

  scope :for_event_notification_by_order, ->(order) { in_order(order).where(state: 'passed') }

  scope :including_samples_from_target, -> { includes(target_asset: { aliquots: :sample }) }
  scope :including_samples_from_source, -> { includes(asset: { aliquots: :sample }) }

  scope :for_order_including_submission_based_requests,
        ->(order) do
          # To obtain the requests for an order and the sequencing requests of its submission (as they are defined
          # as a common element for any order in the submission)
          where(
            [
              'requests.order_id=? OR (requests.order_id IS NULL AND requests.submission_id=?)',
              order.id,
              order.submission.id
            ]
          )
        end

  scope :with_request_type_id, ->(id) { where(request_type_id: id) }

  scope :into_by_id, ->(target_ids) { where(target_asset_id: target_ids) }

  scope :request_type, ->(request_type) { where(request_type_id: request_type) }

  scope :where_has_a_submission, -> { where('submission_id IS NOT NULL') }

  scope :full_inbox, -> { where(state: %w[pending hold]) }
  scope :pipeline_pending,
        ->(include_held = false) { include_held ? where(state: %w[pending hold]) : where(state: 'pending') }
  scope :with_asset, -> { where.not(asset_id: nil) }

  # Ensures the actual record is present
  scope :with_present_asset, -> { joins(:asset).where.not(Receptacle.table_name => { id: nil }) }
  scope :with_target, -> { where('target_asset_id is not null and (target_asset_id <> asset_id)') }
  scope :join_asset, -> { joins(:asset) }
  scope :with_asset_location, -> { includes(asset: :map) }
  scope :siblings_of, ->(request) { where(asset_id: request.asset_id).where.not(id: request.id) }
  scope :asset_on_labware,
        -> do
          joins(:asset)
            .select('requests.*')
            .select('receptacles.labware_id AS labware_id')
            .where.not(receptacles: { labware_id: nil })
        end
  scope :target_asset_on_labware,
        -> do
          joins(:target_asset)
            .select('requests.*')
            .select('receptacles.labware_id AS labware_id')
            .where.not(receptacles: { labware_id: nil })
        end

  scope :without_asset, -> { where('asset_id is null') }
  scope :without_target, -> { where('target_asset_id is null') }
  scope :excluding_states, ->(states) { where.not(state: states) }
  scope :ordered, -> { order(:id) }

  # NOTE: These scopes use preload due to a limitation in the way rails handles custom selects with eager loading
  # https://github.com/rails/rails/issues/15185
  scope :loaded_for_inbox_display,
        -> do
          preload(
            [{ submission: { orders: :study }, asset: [:scanned_into_lab_event, :studies, { labware: :barcodes }] }]
          )
        end
  scope :loaded_for_sequencing_inbox_display,
        -> do
          preload(
            [
              :upstream_requests,
              {
                submission: {
                  orders: :study
                },
                asset: [
                  :requests_as_target,
                  :requests,
                  :most_tagged_aliquot,
                  { labware: %i[barcodes scanned_into_lab_event] }
                ]
              },
              { request_type: :product_line }
            ]
          )
        end
  scope :loaded_for_grouped_inbox_display,
        -> { preload([{ submission: :orders, asset: { labware: %i[purpose barcodes] } }, :target_asset, :order]) }

  scope :for_submission_id, ->(id) { where(submission_id: id) }
  scope :for_asset_id, ->(id) { where(asset_id: id) }
  scope :for_study_ids,
        ->(ids) do
          joins('INNER JOIN aliquots AS al ON requests.asset_id = al.receptacle_id').where(
            ['al.study_id IN (?)', ids]
          ).uniq
        end

  scope :for_study_id, ->(id) { for_study_ids(id) }

  scope :for_initial_study_id, ->(id) { where(initial_study_id: id) }

  scope :for_request_types, ->(types) { joins(:request_type).where(request_types: { key: types }) }

  scope :for_search_query, ->(query) { where(['id=?', query]) }
  scope :for_studies, ->(*studies) { where(initial_study_id: studies) }

  scope :with_assets_for_starting_requests,
        -> do
          includes([:request_metadata, :request_type, :request_events, { asset: :aliquots, target_asset: :aliquots }])
        end
  scope :not_failed, -> { where(['state != ?', 'failed']) }

  scope :multiplexed, -> { joins(:request_type).where(request_types: { for_multiplexing: true }) }

  # Class method calls
  has_metadata do
    belongs_to :primer_panel
    belongs_to :bait_library
  end

  # Do NOT move above 'has_metadata'
  include Request::CustomerResponsibility

  has_one :primer_panel, through: :request_metadata

  # Delegations
  delegate :billable?, to: :request_type, allow_nil: true

  # NOTE: With properties Request#name would have been silently sent through to the property.  With metadata
  # we now need to be explicit in how we want it delegated.
  delegate :name, to: :request_metadata

  delegate :date_for_state, to: :request_events
  delegate :validator_for, to: :request_type
  delegate :role, to: :order_role, allow_nil: true
  delegate :name, to: :request_type, prefix: true

  def self.delegate_validator
    DelegateValidation::AlwaysValidValidator
  end

  def self.for_study(study)
    Request.for_study_id(study.id)
  end

  def self.number_expected_for_submission_id_and_request_type_id(submission_id, request_type_id)
    Request.where(submission_id:, request_type_id:)
  end

  def self.accessioning_required?
    false
  end

  def run_events
    events.loaded? ? events.select { |e| e.message.starts_with?('Run') } : where('message LIKE "Run%"')
  end

  def source_labware
    asset.labware
  end

  def eventful_studies
    initial_study.present? ? [initial_study] : asset_studies
  end

  def current_request_event
    request_events.loaded? ? request_events.detect(&:current?) : request_events.current.last
  end

  def project_id=(project_id)
    raise 'Initial project already set' if initial_project_id

    self.initial_project_id = project_id
  end

  def submission_plate_count
    submission.requests.where(request_type_id:).joins(:source_labware).distinct.count('labware.id')
  end

  def update_responsibilities!
    # Do nothing
  end

  def project=(project)
    return unless project

    self.project_id = project.id
  end

  def study_id=(study_id)
    raise 'Initial study already set' if initial_study_id

    self.initial_study_id = study_id
  end

  def study=(study)
    return unless study

    self.study_id = study.id
  end

  def associated_studies
    return [initial_study] if initial_study.present?
    return asset.studies.uniq if asset.present?
    return submission.studies if submission.present?

    []
  end

  #
  # Passed into cloned aliquots at the beginning of a pipeline to set
  # appropriate options
  #
  #
  # @return [Hash] A hash of aliquot attributes
  #
  def aliquot_attributes
    { study_id: initial_study_id, project_id: initial_project_id, request_id: id }
  end

  def detect_descriptor(name, descriptor_batch: batch)
    # Sort in lab_events_for_batch goes by id ascending, so we use a reverse each, in order to find the most recent
    # descriptor with the passed in 'name'
    # Lazy ensures we stop searching as soon as we find a value
    lab_events_for_batch(descriptor_batch).lazy.reverse_each.map { |e| e.descriptor_value_for(name) }.detect(&:present?)
  end

  def has_passed(batch, task)
    lab_events_for_batch(batch).any? { |event| event.description == task.name }
  end

  # Returns the lab_events associated with `batch`
  # While for the most-part each request only belongs to a single batch at any one time,
  # they may have belonged to other batches historically.
  #
  # @param batch [Batch] The batch to filter events by
  #
  # @return [Array<LabEvent>,LabEvent::ActiveRecord_Associations_CollectionProxy] Events associated with `batch`
  #
  def lab_events_for_batch(batch)
    if lab_events.loaded?
      lab_events.select { |le| le.batch_id == batch&.id }.sort
    else
      lab_events.where(batch_id: batch).order(:created_at, :id)
    end
  end

  def most_recent_event_named(name)
    lab_events_for_batch(batch).reverse.detect { |e| e.description == name }
  end

  def next_requests
    return [] if submission.nil? || next_request_type_id.nil?

    next_requests_via_asset || next_requests_via_submission
  end

  def next_request_type_id
    # May be nil, so can't use lazy assignment
    return @next_request_type_id if instance_variable_defined?(:@next_request_type_id)

    @next_request_type_id = calculate_next_request_type_id
  end

  # CAUTION!: This may not behaves as expected. I'll be deprecating this soon.
  def next_requests_via_asset
    if target_asset.present?
      target_asset.requests.where(submission_id: submission_id, request_type_id: next_request_type_id)
    end
  end

  def next_requests_via_submission
    submission.next_requests_via_submission(self)
  end

  def target_tube
    target_asset if target_asset.is_a?(Tube)
  end

  def previous_failed_requests?
    asset.requests.any?(&:failed?)
  end

  def add_comment(comment, user, title = nil)
    # Unscope comments to fix Rails 6 deprecation warnings. But I *think* this
    # essentially models the new behaviour in 6.1 So should be removable then
    Comment.unscoped { comments.create(description: comment, user: user, title: title) }
  end

  def return_pending_to_inbox!
    raise StandardError, "Can only return pending requests, request is #{state}" unless pending?
  end

  def format_qc_information
    return [] if lab_events.empty?

    events
      .filter_map do |event|
        next if event.family.nil? || %w[pass fail].exclude?(event.family.downcase)

        message = event.message.presence || '(No message was specified)'
        {
          'event_id' => event.id,
          'status' => event.family.downcase,
          'message' => message,
          'created_at' => event.created_at
        }
      end
      .compact
  end

  def copy
    RequestFactory.copy_request(self)
  end

  def cancelable?
    batch_request.nil? && (pending? || blocked?)
  end

  def update_priority
    priority = (self.priority + 1) % 4
    submission.update!(priority:)
  end

  def priority
    submission.try(:priority) || 0
  end

  def request_type_updatable?(_new_request_type)
    pending?
  end

  def customer_accepts_responsibility!
    # Do nothing
  end

  # Adds any pool information to the structure so that it can be reported to client applications
  def update_pool_information(pool_information)
    pool_information[:request_type] = request_type.key
    pool_information[:for_multiplexing] = request_type.for_multiplexing?
  end

  # The date at which the submission was made. In most cases this will be similar to the request's created_at
  # timestamp. We go via submission to ensure that copied requests bear the original timestamp.
  def submitted_at
    # Hopefully we shouldn't get any requests that don't have a submission. But validation is turned off, so
    # we should assume it it possible.
    return '' if submission.nil?

    submission.created_at.strftime('%Y-%m-%d')
  end

  def ready?
    true
  end

  def target_purpose
    nil
  end

  def product_line
    _product_line&.name
  end

  def manifest_processed!
  end

  def self.get_all_comments(request)
    counts = Comment.counts_for_requests([request])
    counts[request.id]
  end

  private

  def calculate_next_request_type_id
    safe_order = order || submission&.orders&.first
    safe_order&.next_request_type_id(request_type_id)
  end
end
