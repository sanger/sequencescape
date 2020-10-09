# frozen_string_literal: true

# This class of verification is for robots where the source plates share
# the same beds as control plates.
class Robot::Verification::SourceDestBeds < Robot::Verification::Base
  def layout_data_object(data_object)
    dest_barcode_index = barcode_to_plate_index(data_object['destination'])
    source_barcode_index = source_barcode_to_plate_index(data_object['destination']) # uses 'mapping' -> 'src_well'
    [dest_barcode_index, source_barcode_index]
  end

  private

  # Returns a hash of plates to indexes sorted by destination well to make sure
  # the plates are put the right way round for the robot
  # e.g. for Tecan 'SCRC1' goes into the 1st row of the fluidigm chip, and 'SCRC2' into the 2nd
  def source_barcode_to_plate_index(destinations)
    # We don't need to sort control and source barcodes for the Tecan, so just
    # don't apply a filter. All source plates will be included
    filter_barcode_to_plate_index(destinations)
  end

  def sort_order
    :row_order
  end
end
