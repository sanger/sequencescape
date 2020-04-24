# frozen_string_literal: true

# require 'lib/nested_validators'
# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
class Plate::QuadCreator
  extend NestedValidation
  include ActiveModel::Model

  attr_accessor :parents, :target_purpose, :user

  validates_nested :creation

  def save
    creation.save && transfer_request_collection.save
    true
  end

  def target_plate
    @creation&.child
  end

  def target_coordinate_for(source_coordinate_name, quadrant_index)
    row_offset = quadrant_index % 2 # q0 -> 0, q1 -> 1, q2 -> 0, q3 -> 1
    col_offset = quadrant_index / 2 # q0 -> 0, q1 -> 0, q2 -> 1, q3 -> 1
    col, row = well_coordinate(source_coordinate_name) # A1 -> 0, 0
    target_col = (col*2)+col_offset
    target_row = (row*2)+row_offset
    Map.location_from_row_and_column(target_row, target_col + 1) # this method expects target_col to be 1-indexed
  end

  private

  def indexed_target_wells
    target_plate.wells.index_by(&:map_description)
  end

  def creation
    @creation ||= PooledPlateCreation.new(user: user, parents: parents.values, child_purpose: target_purpose)
  end

  def transfer_request_collection
    @transfer_request_collection ||= TransferRequestCollection.new(
      user: user,
      transfer_requests_attributes: transfer_requests_attributes
    )
  end

  def transfer_requests_attributes
    # Logic for quad stamping.
    [:quad_1, :quad_2, :quad_3, :quad_4].each_with_index.flat_map do |quadrant_name, quadrant_index|
      next if parents[quadrant_name].blank?
      parents[quadrant_name].wells.map do |well|
        target_coordinate = target_coordinate_for(well.map_description, quadrant_index)
        {
          asset_id: well.id,
          target_asset_id: indexed_target_wells[target_coordinate].id
        }
      end
    end.compact
  end

  #
  # Converts a well name to its co-ordinates
  #
  # @param [<String>] well Name of the well. Eg. A3
  #
  # @return [Array<Integer>] An array of two integers indicating column and row. eg. [0, 2]
  #
  def well_coordinate(well)
    [well[1..-1].to_i - 1, well.upcase.getbyte(0) - 'A'.getbyte(0)]
  end
end
