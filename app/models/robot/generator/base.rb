# frozen_string_literal: true

require_dependency 'robot'
require_dependency 'robot/generator'

# Base class for handling generation of robot picking files for a batch plate
class Robot::Generator::Base
  attr_reader :batch, :plate_barcode

  def initialize(batch: nil, plate_barcode: nil)
    @batch = batch
    @plate_barcode = plate_barcode
  end
end
