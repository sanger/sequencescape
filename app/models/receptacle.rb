# frozen_string_literal: true
# A receptacle is a container for {Aliquot aliquots}, they are associated with
# {Labware}, which represents the physical object which moves round the lab.
# A {Labware} may have a single {Receptacle}, such as in the case of a {Tube}
# or multiple, in the case of a {Plate}.
# Work can be {Request requested} on a particular receptacle.
class Receptacle < Asset # rubocop:todo Metrics/ClassLength
  include Uuid::Uuidable
  include Commentable
  include Transfer::State
  include Aliquot::Remover
  include StudyReport::AssetDetails
  include Receptacle::DownstreamAliquotsRemoval::Mixin

  QC_STATE_ALIASES = { 'passed' => 'pass', 'failed' => 'fail' }.freeze

  belongs_to :labware
  has_many :barcodes, through: :labware
  has_many :parents, through: :labware
  has_many :ancestors, through: :labware
  has_many :descendants, through: :labware

  # We don't do a has_one through as not all receptacles are part of tubes and then
  # we'd have to add racked_tube associations to labware. While we may eventually want to
  # rack different kinds of labware, I'd prefer to avoid making it easier to inadvertently
  # put a tube rack in a tube rack.
  has_one :racked_tube, foreign_key: :tube_id, primary_key: :labware_id

  belongs_to :map

  has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset, foreign_key: :asset_id
  has_many :asset_groups, through: :asset_group_assets
  has_many :qc_results, dependent: :destroy, foreign_key: :asset_id, inverse_of: :asset
  has_many :sample_manifest_assets, dependent: :destroy, foreign_key: :asset_id, inverse_of: :asset
  has_many :sample_manifests, through: :sample_manifest_assets

  delegate :description, to: :map, prefix: true, allow_nil: true

  delegate :human_barcode, :machine_barcode, :barcode_number, to: :labware, allow_nil: true
  delegate :asset_type_for_request_types, to: :labware, allow_nil: true
  delegate :has_stock_asset?, to: :labware, allow_nil: true
  delegate :children, to: :labware, allow_nil: true
  delegate :sequenceable?, to: :labware, allow_nil: true
  delegate :source_plate, :source_plates, to: :labware, allow_nil: true

  # Keeps event behaviour consistent
  delegate :subject_type, to: :labware
  delegate :public_name, to: :labware

  # This really doesn't make sense any more. Should probably migrate legacy data
  # to a barcode type and retire this
  delegate :two_dimensional_barcode, :two_dimensional_barcode=, to: :labware, allow_nil: true

  scope :named, ->(name) { joins(:labware).where(labware: { name: name }) }

  # We accept not only an individual barcode but also an array of them.
  scope :with_barcode,
        lambda { |*barcodes|
          db_barcodes = Barcode.extract_barcodes(barcodes)
          joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
        }
  scope :include_map, -> { includes(:map) }
  scope :located_at, ->(location) { joins(:map).where(maps: { description: location }) }
  scope :located_at_position, ->(position) { joins(:map).readonly(false).where(maps: { description: position }) }

  def any_barcode_matching?(other_barcode)
    barcodes.any? { |barcode| barcode =~ other_barcode }
  end

  self.stock_message_template = 'TubeStockResourceIO'
  self.sample_partial = 'assets/samples_partials/asset_samples'

  has_many :messengers, as: :target, inverse_of: :target
  delegate :scanned_in_date, to: :labware
  delegate :spiked_in_buffer, to: :labware

  has_many :transfer_requests_as_source, class_name: 'TransferRequest', foreign_key: :asset_id
  has_many :transfer_requests_as_target, class_name: 'TransferRequest', foreign_key: :target_asset_id

  has_many :downstream_assets, through: :transfer_requests_as_source, source: :target_asset
  has_many :downstream_wells, through: :transfer_requests_as_source, source: :target_asset, class_name: 'Well'
  has_many :downstream_tubes, through: :transfer_requests_as_source, source: :target_labware, class_name: 'Tube'
  has_many :downstream_plates, through: :downstream_wells, source: :plate

  has_many :upstream_assets, through: :transfer_requests_as_target, source: :asset
  has_many :upstream_wells, through: :transfer_requests_as_target, source: :asset, class_name: 'Well'
  has_many :upstream_tubes, through: :transfer_requests_as_target, source: :source_labware, class_name: 'Tube'
  has_many :upstream_plates, through: :upstream_wells, source: :plate

  has_many :requests, inverse_of: :asset, foreign_key: :asset_id, dependent: :restrict_with_exception
  has_one :source_request,
          class_name: 'Request',
          foreign_key: :target_asset_id,
          dependent: :restrict_with_exception,
          inverse_of: :target_asset
  has_many :requests_as_source,
           class_name: 'Request',
           foreign_key: :asset_id,
           dependent: :restrict_with_exception,
           inverse_of: :asset
  has_many :requests_as_target,
           class_name: 'Request',
           foreign_key: :target_asset_id,
           dependent: :restrict_with_exception,
           inverse_of: :target_asset
  has_many :creation_batches, class_name: 'Batch', through: :requests_as_target, source: :batch
  has_many :source_batches, class_name: 'Batch', through: :requests_as_source, source: :batch
  has_many :source_receptacles, through: :requests_as_target, source: :asset

  # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
  # one aliquot.
  has_many :aliquots,
           lambda { order(tag_id: :asc, tag2_id: :asc) },
           foreign_key: :receptacle_id,
           autosave: true,
           dependent: :destroy,
           inverse_of: :receptacle
  has_many :samples, through: :aliquots
  has_many :studies, -> { distinct }, through: :aliquots
  has_many :projects, -> { distinct }, through: :aliquots
  has_many :aliquot_requests, through: :aliquots, source: :request
  has_one :primary_aliquot, -> { order(:created_at).readonly }, class_name: 'Aliquot'
  has_one :primary_sample, through: :primary_aliquot, source: :sample

  has_many :submitted_assets, foreign_key: :asset_id # Created to associate an asset with an order
  has_many :orders, through: :submitted_assets
  has_many :ordered_studies, through: :orders, source: :study
  has_many :direct_submissions, -> { distinct }, through: :orders, source: :submission

  has_many :tags, through: :aliquots

  # Historically this used to be the only way to jump up to the submission without
  # going via stock-wells. However, newer aliquots are associated with the request.
  # This newer approach (going via aliquot) better handles cross-submission pooling,
  # such as that used in the GBS pipelines.
  # There is currently no direct replacement for this association using the new approach
  # however if you wished to add one:
  # has_many :aliquot_requests, through: :aliquots, source: :request
  # has_many :aliquot_submissions, through: :aliquot_requests, source: :submission
  has_many :submissions, -> { distinct }, through: :transfer_requests_as_target

  # Our receptacle needs to report its tagging status based on the most highly tagged aliquot. This retrieves it
  has_one :most_tagged_aliquot,
          lambda { order(tag2_id: :desc, tag_id: :desc).readonly },
          class_name: 'Aliquot',
          foreign_key: :receptacle_id

  has_many :external_library_creation_requests, foreign_key: :asset_id
  has_many :events_on_requests, through: :requests_as_source, source: :events, validate: false

  # Named scopes for the future
  scope :include_aliquots, -> { includes(aliquots: %i[sample tag bait_library]) }
  scope :include_aliquots_for_api, -> { includes(aliquots: Io::Aliquot::PRELOADS) }
  scope :for_summary, -> { includes(:map, :samples, :studies, :projects) }
  scope :include_creation_batches, -> { includes(:creation_batches) }
  scope :include_source_batches, -> { includes(:source_batches) }
  scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }

  scope :for_study_and_request_type,
        lambda { |study, request_type|
          joins(:aliquots, :requests).where(aliquots: { study_id: study }).where(
            requests: {
              request_type_id: request_type
            }
          )
        }

  # This is a lambda as otherwise the scope selects Receptacles
  scope :with_aliquots, -> { joins(:aliquots) } # rubocop:todo Rails/DuplicateScope

  # Provide some named scopes that will fit with what we've used in the past
  scope :with_sample_id, ->(id) { where(aliquots: { sample_id: Array(id) }).joins(:aliquots) }
  scope :with_sample, ->(sample) { where(aliquots: { sample_id: Array(sample) }).joins(:aliquots) }
  scope :with_contents, -> { joins(:aliquots) } # rubocop:todo Rails/DuplicateScope

  # Scope for caching the samples of the receptacle
  scope :for_bulk_submission, -> { includes(samples: :studies) }

  def update_aliquot_quality(suboptimal_quality)
    aliquots.each { |a| a.update_quality(suboptimal_quality) }
    true
  end

  delegate :tag_count_name, to: :most_tagged_aliquot, allow_nil: true

  # def map_description
  delegate :description, to: :map, prefix: true, allow_nil: true

  def total_comment_count
    comments.size + labware_comment_count
  end

  def labware_comment_count
    labware&.comments&.size || 0
  end

  scope :on_a, ->(klass) { joins(:labware).where(labware: { sti_type: [klass.name, *klass.descendants.map(&:name)] }) }

  # Returns the map_id of the first and last tag in an asset
  # eg 1-96.
  # Caution: Used on barcode labels. Avoid using elsewhere as makes assumptions
  #          about tag behaviour which may change shortly.
  # @return [String,nil] Returns nil is no tags, the map_id is a single tag, or the first and
  #                      last map id separated by a hyphen if multiple tags.
  #
  def tag_range
    map_ids = tags.order(:map_id).pluck(:map_id)
    case map_ids.length
    when 0
      nil
    when 1
      map_ids.first
    else
      "#{map_ids.first}-#{map_ids.last}"
    end
  end

  def compatible_qc_state
    QC_STATE_ALIASES.fetch(qc_state, qc_state) || ''
  end

  def set_qc_state(state)
    self.qc_state = QC_STATE_ALIASES.key(state) || state
    save
    set_external_release(qc_state)
  end

  def been_through_qc?
    qc_state.present?
  end

  def primary_aliquot_if_unique
    primary_aliquot if aliquots.count == 1
  end

  def library_information
  end

  def assign_tag2(tag)
    aliquots.each do |aliquot|
      aliquot.tag2 = tag
      aliquot.save!
    end
  end

  def created_with_request_options
    aliquots.first&.created_with_request_options || {}
  end

  # Library types are still just a string on aliquot.
  def library_types
    aliquots.pluck(:library_type).uniq
  end

  def set_as_library(force: false)
    aliquots.each do |aliquot|
      aliquot.set_library(force: force)
      aliquot.save!
    end
  end

  def outer_request(submission_id)
    transfer_requests_as_target.find_by(submission_id: submission_id).try(:outer_request)
  end

  # All studies related to this asset
  def related_studies
    (ordered_studies + studies).compact.uniq
  end

  def attach_tag(tag, tag2 = nil)
    tags = { tag: tag, tag2: tag2 }.compact
    return if tags.empty?
    raise StandardError, 'Cannot tag an empty asset' if aliquots.empty?

    aliquots.each { |a| a.update!(tags) }
  end

  alias attach_tags attach_tag

  # Contained samples also works on eg. plate
  alias_attribute :contained_samples, :samples

  # We only support wells for the time being
  def latest_stock_metrics(_product, *_args)
    []
  end

  delegate :external_identifier, to: :labware
  delegate :display_name, to: :labware, allow_nil: true

  def name
    labware_name = labware.present? ? labware.try(:name) : '(not on a labware)'
    labware_name ||= labware.display_name # In the event the labware is barcode-less (ie strip tubes) use its name
    labware_name
  end

  def update_from_qc(qc_result)
    Tube::AttributeUpdater.update(self, qc_result)
  end

  delegate :name, to: :labware, prefix: true

  def library_name
    labware.name
  end

  def details
    labware.try(:details).presence || 'Not on labware'
  end

  # Compatibility for v1 API maintains legacy 'type' for assets
  def api_asset_type
    legacy_asset_type.tableize
  end

  # Compatibility for v1 API maintains legacy 'type' for assets
  def legacy_asset_type
    labware.sti_type
  end

  def friendly_name
    labware&.friendly_name || id
  end

  # Returns the name of the position (eg. A1) of the receptacle
  # within the context of any tube-rack it may be contained within
  def absolute_position_name
    racked_tube&.coordinate
  end

  def role
    (requests_as_source.first || aliquot_requests.first).role
  end

  # Groups the requests as target by the same source and returns the most recent request
  # for each source
  #
  # @return [Array<Request>] List of requests as target that pass the condition for the current receptacle
  def most_recent_requests_as_target_group_by_same_source
    # Sorts all requests by id, and then index_by will create an object
    # that will store for every asset_id only the last request (request with higher id),
    # ignoring any other request for the same asset_id.
    # From this object we return the list of values, which is an already flattened list
    requests_as_target.order(id: :asc).index_by(&:asset_id).values
  end

  private

  def set_external_release(state) # rubocop:todo Metrics/MethodLength
    update_external_release do
      if state == 'failed'
        self.external_release = false
      elsif state == 'passed'
        self.external_release = true
      elsif state == 'pending'
        self # Do nothing
      elsif state.nil?
        self # TODO: Ignore for the moment, correct later
      elsif ['scanned_into_lab'].include?(state.to_s)
        self # TODO: Ignore for the moment, correct later
      else
        raise StandardError, "Invalid external release state #{state.inspect}"
      end
    end
  end

  def update_external_release
    external_release_nil_before = external_release.nil?
    yield
    save!
    events.create_external_release!(!external_release_nil_before) unless external_release.nil?
  end
end
