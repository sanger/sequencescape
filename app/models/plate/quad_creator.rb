# frozen_string_literal: true

# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
class Plate::QuadCreator
  include ActiveModel::Model

  attr_accessor :target_purpose, :user, :user_barcode

  validates :user, presence: { message: 'could not be found' }
  validate :all_parents_acceptable
  validate :at_least_one_parent

  def save
    valid? && creation.save && transfer_request_collection.save && quadrant_metadata_collection.save
  end

  def target_plate
    @creation&.child
  end

  def parent_barcodes=(quad_barcodes)
    @parent_barcodes = quad_barcodes
    found_parents = Labware.with_barcode(quad_barcodes.values)
    @parents =
      quad_barcodes.transform_values do |barcode|
        found_parents.detect { |candidate| candidate.any_barcode_matching?(barcode) } || :not_found
      end
  end

  def parent_barcodes
    @parent_barcodes ||= @parents.transform_values(&:machine_barcode)
  end

  def target_purpose_id
    @target_purpose&.id
  end

  private

  def all_parents_acceptable # rubocop:todo Metrics/MethodLength
    @parents.each do |location, parent|
      case parent
      when Plate, TubeRack
        next if parent.size == 96

        add_error(location, 'is the wrong size')
      when :not_found
        add_error(location, 'could not be found')
      else
        add_error(location, 'is not a plate or tube rack')
      end
    end
  end

  def at_least_one_parent
    errors.add(:parent_barcodes, 'Please fill in at least one quadrant.') if @parents.empty?
  end

  def add_error(location, message)
    location_name = location.to_s.humanize
    errors.add(:parent_barcodes, "#{location_name} (#{parent_barcodes[location]}) #{message}")
  end

  def indexed_target_wells
    @indexed_target_wells ||= target_plate.wells.index_by(&:map_description)
  end

  def creation
    @creation ||= PooledPlateCreation.new(user:, parents: @parents.values, child_purpose: target_purpose)
  end

  def transfer_request_collection
    @transfer_request_collection ||=
      TransferRequestCollection.new(user:, transfer_requests_attributes:)
  end

  def transfer_requests_attributes
    # Logic for quad stamping.
    %w[quad_1 quad_2 quad_3 quad_4].each_with_index.flat_map do |quadrant_name, quadrant_index|
      next if @parents[quadrant_name].blank?

      @parents[quadrant_name].receptacles_with_position.map do |receptacle|
        target_coordinate = Plate::QuadCreator.target_coordinate_for(receptacle.absolute_position_name, quadrant_index)
        { asset_id: receptacle.id, target_asset_id: indexed_target_wells[target_coordinate].id }
      end
    end.compact
  end

  # Sets up the metadata we store on the destination plate that tells us which source went into which quadrant.
  # This will get displayed on the plate view in Sequencescape.
  def quadrant_metadata_collection
    quadrant_metadata = {}
    %w[quad_1 quad_2 quad_3 quad_4].each_with_index do |quadrant_name, quadrant_index|
      quadrant_metadata["Quadrant #{quadrant_index + 1}"] = parent_barcodes[quadrant_name] || 'Empty'
    end
    @quadrant_metadata_collection ||=
      CustomMetadatumCollection.new(user:, asset: target_plate, metadata: quadrant_metadata)
  end

  class << self
    #
    # Calculate the target coordinate for a source coordinate and quadrant number
    #
    # @param source_coordinate_name [String] Location name of the well or tube. Eg. H12
    # @param quadrant_index [int] Quadrant index 1-4 e.g. 4
    #
    # @return [String] The target coordinate in the destination 384-well plate, e.g. P24
    #
    def target_coordinate_for(source_coordinate_name, quadrant_index)
      row_offset = quadrant_index % 2 # q0 -> 0, q1 -> 1, q2 -> 0, q3 -> 1
      col_offset = quadrant_index / 2 # q0 -> 0, q1 -> 0, q2 -> 1, q3 -> 1
      col, row = locn_coordinate(source_coordinate_name) # A1 -> 0, 0
      target_col = (col * 2) + col_offset
      target_row = (row * 2) + row_offset
      Map.location_from_row_and_column(target_row, target_col + 1) # this method expects target_col to be 1-indexed
    end

    private

    #
    # Converts a well or tube location name to its co-ordinates
    #
    # @param [<String>] Location name of the well or tube. Eg. A3
    #
    # @return [Array<Integer>] An array of two integers indicating column and row. eg. [0, 2]
    #
    def locn_coordinate(locn_name)
      [locn_name[1..].to_i - 1, locn_name.upcase.getbyte(0) - 'A'.getbyte(0)]
    end
  end
end
