# frozen_string_literal: true
# A Type of robot

# This class of verification is for robots where the source plates and control
# plates have distinct beds
class Robot::Verification::SourceDestControlBeds < Robot::Verification::Base
  def layout_data_object(data_object)
    destination = data_object['destination']
    source = data_object['source']
    dest_barcode_index = barcode_to_plate_index(destination)
    source_barcode_index = source_barcode_to_plate_index(destination, source)
    control_barcode_index = control_barcode_to_plate_index(destination, source)
    [dest_barcode_index, source_barcode_index, control_barcode_index]
  end

  def valid_plate_locations?(params, batch, robot, expected_plate_layout) # rubocop:todo Metrics/MethodLength
    return false unless super
    unless valid_control_plates_on_robot?(
             params[:control_bed_barcodes],
             params[:control_plate_barcodes],
             robot,
             batch,
             expected_plate_layout
           )
      return false
    end

    true
  end

  def valid_control_plates_on_robot?(beds, plates, robot, batch, all_expected_plate_layout)
    # it is valid for this type of robot not to have any control plates in the batch
    # e.g. for a second batch onto a partial destination plate that already contains controls
    # e.g. when no controls are needed
    return true if all_expected_plate_layout[2].blank?

    valid_plates_on_robot?(beds, plates, 'CTRL', robot, batch, all_expected_plate_layout[2])
  end

  private

  def sort_order
    :column_order
  end

  #
  # Returns a hash of plates to indexes sorted by destination well to make sure
  # the plates are put the right way round for the robot
  #
  # @param [Hash] destinations The destination attribute of the data object generated by
  #                            {Batch::CommonRobotBehaviour.source_barcode_to_plate_index}
  # @param [Hash] sources The source attribute of the data object generated by
  #                       {Batch::CommonRobotBehaviour.source_barcode_to_plate_index}
  # @return [Hash] Hash of plate barcodes mapped to their bed index
  #
  def source_barcode_to_plate_index(destinations, sources)
    filter_barcode_to_plate_index(destinations) { |barcode| !sources.dig(barcode, 'control') }
  end

  # Returns a hash of plates to indexes sorted by destination well to make sure
  # the plates are put the right way round for the robot
  # e.g. for Tecan 'SCRC1' goes into the 1st row of the fluidigm chip, and 'SCRC2' into the 2nd
  def control_barcode_to_plate_index(destinations, sources)
    filter_barcode_to_plate_index(destinations) { |barcode| sources.dig(barcode, 'control') }
  end
end
