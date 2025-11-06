# frozen_string_literal: true

require 'lab_where_client'

# https://github.com/sanger/sequencescape/raw/master/docs/images/plate.jpg
#
# A plate is a piece of labware made up of a number of {Well wells}. This class represents the physical piece of
# plastic.
#
# - {PlatePurpose}: describes the role a plate has in the lab. In some cases a plate's purpose may change as it gets
#                   processed.
# - {Well}: Plates can have multiple wells (most often 96 or 384) each of which can contain multiple samples.
# - {PlateType}: Identifies the plates form factor, typically provided to robots to ensure tips are positioned
#                correctly.
#
class Plate < Labware # rubocop:todo Metrics/ClassLength
  include Api::PlateIo::Extensions
  include ModelExtensions::Plate
  include Transfer::Associations
  include Transfer::State::PlateState
  include Asset::Ownership::Owned
  include Plate::FluidigmBehaviour
  include Plate::PoolingMetadata
  include PlateCreation::CreationChild
  include Barcode::Barcodeable

  extend QcFile::Associations

  class_attribute :default_plate_size

  # Shouldn't actually be falling back to this, but its here just in case
  self.sample_partial = 'assets/samples_partials/plate_samples'
  self.per_page = 50
  self.default_plate_size = 96
  self.receptacle_class = 'Well'

  has_qc_files

  belongs_to :plate_purpose, inverse_of: :plates
  belongs_to :purpose, foreign_key: :plate_purpose_id
  has_many :wells, inverse_of: :plate, foreign_key: :labware_id do # rubocop:todo Metrics/BlockLength
    # rubocop:todo Metrics/MethodLength
    def construct! # rubocop:todo Metrics/AbcSize
      transaction do
        plate = proxy_association.owner
        plate
          .maps
          .in_row_major_order
          .ids
          .map { |location_id| { map_id: location_id } }
          .tap do |wells|
            plate.wells.import(wells)
            ids = plate.wells.ids
            well_type = Well.base_class.name

            # These would usually be handled in after create callbacks, however
            # import does not fire these, and we want to create them in bulk anyway
            WellAttribute.import(ids.map { |well| { well_id: well } })
            Uuid.import(
              ids.map { |well| { resource_id: well, resource_type: well_type, external_id: Uuid.generate_uuid } }
            )

            # Warren::Message::Short keeps track of the class (Well) and id, and gets sent after
            # the transaction completes. This avoids us needing to instantiate wells, keeping the memory footprint
            # down.
            ids.each { |id| Warren::Message::Short.new(class_name: 'Well', id: id).queue(Warren.handler) }
          end
      end
    end

    # rubocop:enable Metrics/MethodLength

    # Returns the wells with their pool identifier included
    # @note This is a method defined on the well association, and can be considered a scope.
    # Ie. You can do plate.wells.with_pool_id.located_at(['A1'])
    # It is a little special in that its behaviour is dependent on the {PlatePurpose#pool_wells plate purpose}.
    # In practice this lets wells on PlatePurpose::Initial to pull their information from the requests, whereas
    # other purposes jump back to the stock wells.
    # Given this is usually called by the transfers themselves, prior to the transfer of the aliquots
    # it can't be replaced purely by using request on aliquot (as it is partly responsible for setting that)
    # however we can almost certainly simplify this whole process somewhat.
    def with_pool_id
      proxy_association.owner.plate_purpose.pool_wells(self)
    end

    #
    # Returns a hash of wells, indexed by the well name (map_description)
    #
    # @return [Hash] eg. { 'A1' => #<Well map_description: 'A1'>, 'B1' => #<Well map_description: 'B1'> }
    def indexed_by_location
      @index_well_cache ||= index_by(&:map_description)
    end
  end
  has_many :well_requests_as_target, through: :wells, source: :requests_as_target
  has_many :well_requests_as_source, through: :wells, source: :requests_as_source
  has_many :orders_as_target, -> { distinct }, through: :well_requests_as_target, source: :order

  # This association cannot be declared earlier, as it depends on the well_requests_as_target association.
  include SubmissionPool::Association::Plate

  # We use stock well associations here as stock_wells is already used to generate some kind of hash.
  has_many :stock_requests, -> { distinct }, through: :stock_well_associations, source: :requests
  has_many :stock_well_associations, -> { distinct }, through: :wells, source: :stock_wells
  has_many :stock_orders, -> { distinct }, through: :stock_requests, source: :order
  has_many :extraction_attributes, foreign_key: 'target_id'
  has_many :siblings, through: :parents, source: :children

  # Transfer requests into a plate are the requests leading into the wells of said plate.
  has_many :transfer_requests, through: :wells, source: :transfer_requests_as_target
  has_many :transfer_request_collections, -> { distinct }, through: :transfer_requests_as_source

  # The default state for a plate comes from the plate purpose
  delegate :default_state, to: :plate_purpose, allow_nil: true

  # Used to unify interface with TubeRacks. Returns a list of all receptacles {Well wells}
  # with position information included for aid performance
  def receptacles_with_position
    wells.includes(:map)
  end

  # The state of a plate loosely defines what has happened to it. In most cases it is determined
  # by aggregating the state of transfer requests into the wells, although exact behaviour is determined
  # by the {PlatePurpose}. State typically only works for pipeline application plates. In general:
  #
  # - pending: The plate has been registered, but it empty.
  # - started: The plate contains samples, but required further processing
  # - passed: Work on the plate is complete, and it can be transferred to another target
  # - failed: The plate failed QC and can not be progressed further
  # - cancelled: The plate is no longer required and should be ignored.
  #
  # @return [String] Name of the state the plate is in
  def state
    plate_purpose&.state_of(self)
  end

  # Modifies the recorded volume information of all wells on a plate by volume_change
  # @param volume_change [Numeric] The adjustment to apply to all wells (in ul).
  #                                Negative values reduce the target volume, positive values increase it.
  #
  # @return [Void]
  def update_volume(volume_change)
    ActiveRecord::Base.transaction { wells.each { |well| well.update_volume(volume_change) } }
  end

  #
  # Counts the number of wells containing one or more aliquots.
  # @note Does not take into account the {Sample#empty_supplier_sample_name} flag on older samples
  #
  # @return [Integer] The number of wells with samples
  def occupied_well_count
    wells.with_contents.count
  end

  #
  # Called when cherrypicking is completed to allow the plate to trigger any callbacks,
  # such as broadcasting Fluidigm plates to the warehouse.
  # This behaviour varies based on the PlatePurpose
  #
  # @return [Void]
  def cherrypick_completed
    plate_purpose.cherrypick_completed(self)
  end

  # The type of the barcode is delegated to the plate purpose because that governs the number of wells
  delegate :barcode_type, to: :plate_purpose, allow_nil: true
  delegate :asset_shape, to: :plate_purpose, allow_nil: true
  delegate :dilution_factor, :dilution_factor=, to: :plate_metadata

  # Submissions on requests out of the plate
  # May not have been started yet
  has_many :waiting_submissions, -> { distinct }, through: :well_requests_as_source, source: :submission

  def submission_ids
    @submission_ids ||= in_progress_submissions.ids
  end

  def submission_ids_as_source
    @submission_ids_as_source ||= waiting_submissions.ids
  end

  # Prioritised the submissions that have been made from the plate
  # then falls back onto the ones under which the plate was made
  def all_submission_ids
    submission_ids_as_source.presence || submission_ids
  end

  def submissions
    waiting_submissions.presence || in_progress_submissions
  end

  def iteration
    iter =
      siblings # assets sharing the same parent
        .where(plate_purpose_id:, sti_type:) # of the same purpose and type
        .where("#{self.class.table_name}.created_at <= ?", created_at) # created before or at the same time
        .count(:id) # count the siblings.

    iter.zero? ? nil : iter # Maintains compatibility with legacy version
  end

  def comments
    @comments ||= CommentsProxy::Plate.new(self)
  end

  def priority
    waiting_submissions.maximum(:priority) || in_progress_submissions.maximum(:priority) || 0
  end

  before_create :set_plate_name_and_size

  scope :with_sample, ->(sample) { includes(:contained_samples).where(samples: { id: sample }) }
  scope :with_requests, ->(requests) { includes(wells: :requests).where(requests: { id: requests }).distinct }
  scope :output_by_batch, ->(batch) { joins(wells: { requests_as_target: :batch }).where(batches: { id: batch }) }
  scope :with_wells, ->(wells) { joins(:wells).where(receptacles: { id: wells.map(&:id) }).distinct }

  has_many :descendant_plates,
           class_name: 'Plate',
           through: :links_as_ancestor,
           foreign_key: :ancestor_id,
           source: :descendant
  has_many :descendant_tubes,
           class_name: 'Tube',
           through: :links_as_ancestor,
           foreign_key: :ancestor_id,
           source: :descendant
  has_many :descendant_lanes,
           class_name: 'Lane::Labware',
           through: :links_as_ancestor,
           foreign_key: :ancestor_id,
           source: :descendant
  has_many :tag_layouts, dependent: :destroy

  scope :with_descendants_owned_by,
        ->(user) { joins(descendant_plates: :plate_owner).where(plate_owners: { user_id: user }).distinct }

  scope :source_plates, -> { joins(:plate_purpose).where('plate_purposes.id = plate_purposes.source_purpose_id') }

  scope :with_wells_and_requests,
        -> do
          eager_load(
            wells: [
              :uuid_object,
              :map,
              {
                requests_as_target: [
                  { initial_study: :uuid_object },
                  { initial_project: :uuid_object },
                  { asset: { aliquots: :sample } }
                ]
              }
            ]
          )
        end

  def maps
    Map.where_plate_size(size).where_plate_shape(asset_shape)
  end

  def find_well_by_name(well_name)
    wells.loaded? ? wells.indexed_by_location[well_name] : wells.located_at_position(well_name).first
  end
  alias find_well_by_map_description find_well_by_name

  def plate_rows
    ('A'..('A'.getbyte(0) + height - 1).chr.to_s).to_a
  end

  def plate_columns
    (1..width)
  end

  def plate_type
    labware_type&.name || Sequencescape::Application.config.plate_default_type
  end

  def plate_type=(plate_type)
    self.labware_type = PlateType.find_by(name: plate_type)
  end

  def details
    purpose.try(:name) || 'Unknown plate purpose'
  end

  def self.plate_ids_from_requests(requests)
    with_requests(requests).pluck(:id)
  end

  def stock_plate?
    return true if plate_purpose.nil?

    plate_purpose.stock_plate? && plate_purpose.attached?(self)
  end

  #
  # Attempts to find the 'stock_plate' for the plate. However this is a fairly
  # nebulous concept. Often it means the plate that first entered a pipeline,
  # but in other cases it can be the XP plate part way through the process. Further
  # complication comes from tubes which pool across multiple plates, where identifying
  # a single stock plate is meaningless. In other scenarios, you split plates out again
  # and the asset link graph is insufficient.
  #
  # JG: 2021-02-11:
  # See https://github.com/sanger/sequencescape/issues/3040 for more information
  #
  # @deprecated Do not use this for new behaviour.
  #
  #
  # @return [Plate, nil] The stock plate if found
  #
  def stock_plate
    @stock_plate ||= stock_plate? ? self : lookup_stock_plate
  end
  deprecate stock_plate: 'Stock plate is nebulous and can easily lead to unexpected behaviour',
            deprecator: Rails.application.deprecators[:sequencescape]

  def self.create_with_barcode!(*args, &)
    attributes = args.extract_options!
    attributes[:sanger_barcode] ||= PlateBarcode.create_barcode
    create!(attributes, &)
  end

  def number_of_blank_samples
    wells.with_blank_samples.count
  end

  def scored?
    wells.any?(&:get_gel_pass)
  end

  def buffer_required?
    wells.any?(&:buffer_required?)
  end

  #
  # Given a list of well  map_descriptions (eg. A1), returns those not present on the plate
  #
  # @param [Array] positions Array of positions to test
  #
  # @return [Array] Array of invalid positions
  #
  def invalid_positions(positions)
    (positions.uniq - unique_positions_on_plate).sort
  end

  def unique_positions_on_plate
    maps.distinct.pluck(:description)
  end

  def name_for_label
    name
  end

  extend Metadata

  has_metadata {}

  def height
    asset_shape.plate_height(size)
  end

  def width
    asset_shape.plate_width(size)
  end

  # This method returns a map from the wells on the plate to their stock well.
  def stock_wells # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    # Optimisation: if the plate is a stock plate then it's wells are it's stock wells!]
    if stock_plate?
      wells.with_pool_id.index_with { |w| [w] }
    else
      wells
        .include_stock_wells
        .with_pool_id
        .each_with_object({}) do |w, store|
          storted_stock_wells = w.stock_wells.sort_by { |sw| sw.map.column_order }
          store[w] = storted_stock_wells unless storted_stock_wells.empty?
        end
        .tap { |stock_wells_hash| raise "No stock plate associated with #{id}" if stock_wells_hash.empty? }
    end
  end

  def convert_to(new_purpose)
    update!(plate_purpose: new_purpose)
  end

  def compatible_purposes
    PlatePurpose.compatible_with_purpose(purpose)
  end

  def well_hash
    @well_hash ||= wells.include_map.includes(:well_attribute).index_by(&:map_description)
  end

  def update_qc_values_with_parser(parser)
    ActiveRecord::Base.transaction do
      qc_assay = QcAssay.new
      parser.each_well_and_parameters do |position, well_updates|
        # We might have a nil well if a plate was only partially cherrypicked
        well = well_hash[position] || next
        well_updates.each do |attribute, value|
          QcResult.create!(
            asset: well,
            key: attribute,
            unit_value: value,
            assay_type: parser.assay_type,
            assay_version: parser.assay_version,
            qc_assay: qc_assay
          )
        end
      end
    end
    true
  end

  # Finds the product line (= team) of the requests coming out of this plate's 'stock plate'.
  # Written at a time when requests weren't recorded on the aliquot, so could be re-written in a less convoluted way.
  def team
    ProductLine
      .joins(
        [
          'INNER JOIN request_types ON request_types.product_line_id = product_lines.id',
          'INNER JOIN requests ON requests.request_type_id = request_types.id',
          'INNER JOIN well_links ON well_links.source_well_id = requests.asset_id AND well_links.type = "stock"',
          'INNER JOIN receptacles AS re ON re.id = well_links.target_well_id'
        ]
      )
      .find_by(['re.labware_id = ?', id])
      .try(:name) || 'UNKNOWN'
  end

  alias friendly_name human_barcode
  def subject_type
    'plate'
  end

  # Plates use a different counter to tubes, and prior to the foreign barcodes update
  # this method would have fallen back to Barcodable#generate tubes, and potentially generated
  # an invalid plate barcode. In the future we probably want to scrap this approach entirely,
  # and generate all barcodes in the plate style. (That is, as part of the factory on, eg. plate purpose)
  def generate_barcode
    raise StandardError,
          "#generate_barcode has been called on plate, which wasn't supposed to happen, and probably indicates a bug."
  end

  def sanger_barcode=(barcode)
    barcodes << barcode
  end

  def after_comment_addition(comment)
    comments.add_comment_to_submissions(comment)
  end

  def related_studies
    studies
  end

  def wells_in_row_order
    wells.loaded? ? wells.sort_by(&:row_order) : wells.in_row_major_order
  end

  def wells_in_column_order
    wells.loaded? ? wells.sort_by(&:column_order) : wells.in_column_major_order
  end

  # When Cherrypicking, especially on the Hamilton, control plates get placed
  # on a seperate bed. ControlPlates overide this.
  # @return [false]
  def pick_as_control?
    false
  end

  private

  def lookup_stock_plate
    spp = PlatePurpose.considered_stock_plate.pluck(:id)
    ancestors.order(id: :desc).find_by(plate_purpose_id: spp)
  end

  def set_plate_name_and_size
    self.name = "Plate #{human_barcode}" if name.blank?
    self.size = default_plate_size if size.nil?
  end
end
