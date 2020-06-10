# frozen_string_literal: true

# This class of verification is for robots where the source plates share
# the same beds as control plates.
class Robot::Verification::SourceDestBeds < Robot::Verification::Base
  private

  def layout_data_object(data_object)
    dest_barcode_index = Sanger::Robots::Tecan::Generator.barcode_to_plate_index(data_object['destination'])
    source_barcode_index = Sanger::Robots::Tecan::Generator.source_barcode_to_plate_index(data_object['destination'])
    [dest_barcode_index, source_barcode_index]
  end
end
