# frozen_string_literal: true

# Base class for handling generation of robot picking files for a batch plate
class Robot::Generator::Base
  attr_reader :batch, :plate_barcode, :source_barcode_index, :dest_barcode_index, :ctrl_barcode_index, :picking_data

  def initialize(batch: nil, plate_barcode: nil, picking_data: nil, layout: nil, total_volume: nil)
    @batch = batch
    @plate_barcode = plate_barcode
    @picking_data = picking_data
    @dest_barcode_index, @source_barcode_index, @ctrl_barcode_index = layout
    @total_volume = total_volume
  end

  def total_volume
    @total_volume ||= @batch&.total_volume_to_cherrypick.to_i
  end

  # The MIME type of the generated file.
  def type
    'text/plain'
  end
end
