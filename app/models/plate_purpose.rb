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

  broadcast_via_warren

  scope :compatible_with_purpose, ->(purpose) {
    if purpose.nil?
      none
    else
      where(target_type: purpose.target_type).order(name: :asc)
    end
  }

  scope :cherrypickable_as_target, -> { where(cherrypickable_target: true) }
  scope :for_submissions, ->() do
    where('stock_plate = true OR name = "Working Dilution"')
      .order(stock_plate: :desc)
  end
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

  # Updates the state of the specified plate to the specified state.  The basic implementation does this by updating
  # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
  # relate to all wells of the plate, otherwise only the selected ones are updated.
  # @param plate [Plate] The plate being updated
  # @param state [String] The desired target state
  # @param user [User] The person to associate with the action
  # @param contents [nil, Array] Array of well locations to update, leave nil for ALL wells
  # @param customer_accepts_responsibility [Boolean] The customer proceeded against advice and will still be charged
  #                                                  in the the event of a failure
  #
  # @return [Void]
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    state_changer.new(
      labware: plate,
      target_state: state,
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    ).update_labware_state
  end

  # Set the class to PlatePurpose::Input is set to true.
  # Allows creation of the input plate purposes through the API
  # without directly exposing our class names.
  #
  # @param [Bool] is_input Set to true to assign the sti type to PlatePurpose::Input
  def input_plate=(is_input)
    self.type = 'PlatePurpose::Input' if is_input
  end

  def pool_wells(wells)
    _pool_wells(wells)
      .joins('LEFT OUTER JOIN uuids AS pool_uuids ON pool_uuids.resource_type="Submission" AND pool_uuids.resource_id=submission_id')
      .select('pool_uuids.external_id AS pool_uuid')
      .readonly(false)
      .tap do |wells_with_pool|
        raise StandardError, 'Cannot deal with a well in multiple pools' if wells_with_pool.group_by(&:id).any? do |_, multiple_pools|
                                                                              multiple_pools.uniq.size > 1
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

  def create!(*args, &block)
    attributes          = args.extract_options!
    do_not_create_wells = args.first.present?
    attributes[:size] ||= size
    attributes[:purpose] = self
    number = attributes.delete(:barcode)
    prefix = (attributes.delete(:barcode_prefix) || barcode_prefix).prefix
    attributes[:sanger_barcode] ||= { prefix: prefix, number: number }
    target_class.create_with_barcode!(attributes, &block).tap do |plate|
      plate.wells.construct! unless do_not_create_wells
    end
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
require_dependency 'illumina_c/al_libs_tagged_purpose'
require_dependency 'illumina_c/lib_pcr_purpose'
require_dependency 'illumina_c/lib_pcr_xp_purpose'
require_dependency 'illumina_c/stock_purpose'
require_dependency 'illumina_htp/downstream_plate_purpose'
require_dependency 'illumina_htp/final_plate_purpose'
require_dependency 'illumina_htp/normalized_plate_purpose'
require_dependency 'illumina_htp/pooled_plate_purpose'
require_dependency 'illumina_htp/post_shear_qc_plate_purpose'
require_dependency 'plate_purpose/initial_purpose'
require_dependency 'pulldown/initial_plate_purpose'
require_dependency 'pulldown/library_plate_purpose'
