# frozen_string_literal: true

require_dependency 'robot'
require_dependency 'robot/generator'

# Base class for handling generation of robot picking files for a batch plate
class Robot::Generator::Base
  attr_reader :batch, :plate_barcode, :source_barcode_index, :dest_barcode_index, :ctrl_barcode_index

  def initialize(batch: nil, plate_barcode: nil, picking_data: nil, layout: nil)
    @batch = batch
    @plate_barcode = plate_barcode
    @picking_data = picking_data
    @dest_barcode_index, @source_barcode_index, @ctrl_barcode_index = layout
  end

  def picking_data
    @picking_data ||= Robot::PickData.new(@batch, @plate_barcode).picking_data
  end

  # The MIME type of the generated file.
  def type
    'text/plain'
  end
end
