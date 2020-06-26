# frozen_string_literal: true

# Handles the generation for robot driver files, mostly in association with the
# {CherrypickingPipeline}
# A request to eg.
# batches/1/robots/3/driver_file
# Will generate a pick list for batch 1, using the generator specified for robot 3
# The barcode parameter can be used to specify a specific target plate
class DriverFilesController < ApplicationController
  before_action :find_resources

  def show
    @plate_barcode = @batch.plate_barcode(params[:barcode])
    @pick_number = params[:pick_number]
    # TODO: change generator to take the pick number
    generator = @robot.generator(batch: @batch, plate_barcode: @plate_barcode)
    send_data generator.as_text, type: generator.type,
                                 filename: generator.filename,
                                 disposition: 'attachment'
  end

  private

  def find_resources
    @batch = Batch.find(params[:batch_id])
    @robot = Robot.find(params[:robot_id])
  end
end
