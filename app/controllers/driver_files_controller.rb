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
    generator = @robot.generator(batch: @batch, plate_barcode: @plate_barcode, pick_number: pick_number,
                                 generator_id: generator_id)
    base_filename = "#{@batch.id}_batch_#{@plate_barcode}_#{pick_number}"
    send_data generator.as_text,
              type: generator.type,
              filename: generator.filename(base_filename),
              disposition: 'attachment'
  end

  private

  def generator_id
    params.require(:generator_id).to_i
  end

  def pick_number
    params.require(:pick_number).to_i
  end

  def find_resources
    @batch = Batch.find(params[:batch_id])
    @robot = Robot.find(params[:robot_id])
  end
end
