# The standard {Purpose} class for plates. This defines the standard behaviour,
# and is the class used for the majority of PlatePurposes.
#
# @note JG: Generally I have been trying to eliminate as much of the purpose specific
#       behaviour as possible, and have pushed the business logic outwards towards the
#       pipeline applications themselves. This is to try and reduce the overall complexity
#       or Sequencescape models, reduce coupling between Sequencescape and its clients, and
#       to make behaviour of individual plates more predictable. This is intended to
#       increase the flexibility and adaptability of the pipelines.
#
# {include:Purpose}
class PlatePurpose < Purpose
  self.default_prefix = 'DN'

  # includes / extends
  include SharedBehaviour::Named
  include Purpose::Relationship::Associations

  self.state_changer = StateChanger::StandardPlate

  broadcast_with_warren

  scope :compatible_with_purpose,
        ->(purpose) { purpose.nil? ? none : where(target_type: purpose.target_type).order(name: :asc) }

  scope :cherrypickable_as_target, -> { where(cherrypickable_target: true) }
  scope :for_submissions, -> { where('stock_plate = true OR name = "Working Dilution"').order(stock_plate: :desc) }
  scope :considered_stock_plate, -> { where(stock_plate: true) }

  before_validation :set_default_target_type
  before_validation :set_default_printer_type

  belongs_to :asset_shape, optional: false

  def asset_shape
    super || AssetShape.default
  end

  alias library_source_plate source_plate
  alias library_source_plates source_plates

  def cherrypick_completed(plate)
    messenger_creators.each { |creator| creator.create!(plate) }
  end

  def plate_height
    asset_shape.plate_height(size)
  end

  def plate_width
    asset_shape.plate_width(size)
  end

  # The state of a plate is based on the transfer requests.
  def state_of(plate)
    plate.state_from(plate.transfer_requests)
  end

  # Set the class to PlatePurpose::Input is set to true.
  # Allows creation of the input plate purposes through the API
  # without directly exposing our class names.
  #
  # @param [Bool] is_input Set to true to assign the sti type to PlatePurpose::Input
  def input_plate=(is_input)
    self.type = 'PlatePurpose::Input' if is_input
  end

  def pool_wells(wells) # rubocop:todo Metrics/MethodLength
    _pool_wells(wells)
      .joins(
        'LEFT OUTER JOIN uuids AS pool_uuids ON pool_uuids.resource_type="Submission" AND pool_uuids.resource_id=submission_id'
      )
      .select('pool_uuids.external_id AS pool_uuid')
      .readonly(false)
      .tap do |wells_with_pool|
        if wells_with_pool.group_by(&:id).any? { |_, multiple_pools| multiple_pools.uniq.size > 1 }
          raise StandardError, 'Cannot deal with a well in multiple pools'
        end
      end
  end

  include Api::PlatePurposeIO::Extensions

  self.per_page = 500

  # TODO: change to purpose_id
  has_many :plates

  def self.stock_plate_purpose
    PlatePurpose.create_with(stock_plate: true, cherrypickable_target: true).find_or_create_by!(name: 'Stock Plate')
  end

  def size
    super || 96
  end

  def create!(*args, &block) # rubocop:todo Metrics/AbcSize
    attributes = args.extract_options!
    do_not_create_wells = args.first.present?
    attributes[:size] ||= size
    attributes[:purpose] = self
    number = attributes.delete(:barcode)
    prefix = (attributes.delete(:barcode_prefix) || barcode_prefix).prefix
    attributes[:sanger_barcode] ||= { prefix: prefix, number: number }
    target_class
      .create_with_barcode!(attributes, &block)
      .tap { |plate| plate.wells.construct! unless do_not_create_wells }
  end

  def cherrypick_in_rows?
    cherrypick_direction == 'row'
  end

  def attatched?(_plate)
    true
  end

  def child_plate_purposes
    child_purposes.where_is_a(PlatePurpose)
  end

  def source_wells_for(stock_wells)
    stock_wells
  end

  private

  def _pool_wells(wells)
    wells.pooled_as_target_by_transfer
  end

  def set_default_target_type
    self.target_type ||= 'Plate'
  end

  def set_default_printer_type
    self.barcode_printer_type ||= BarcodePrinterType96Plate.first
  end
end

# Ensure rails eager loading behaves as intended
# We should consider renaming our classes to make this easier to maintain
require_dependency 'dilution_plate_purpose'
require_dependency 'plate_purpose/input'
require_dependency 'qcable_library_plate_purpose'
require_dependency 'qcable_plate_purpose'
require_dependency 'plate_purpose/initial_purpose'
