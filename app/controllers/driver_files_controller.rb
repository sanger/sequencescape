# frozen_string_literal: true

# Handles the generation for robot driver files, mostly in association with the
# {CherrypickingPipeline}
# A request to eg.
# batches/1/robots/3/driver_file
# Will generate a pick list for batch 1, using the generator specified for robot 3
# The barcode parameter can be used to specify a specific target plate
class DriverFilesController < ApplicationController
  before_action :find_resources

  # Generates and sends the robot driver file.
  #
  # @note Following parameters are required:
  #   - batch_id: the id of the {Batch} (path parameter)
  #   - robot_id: the id of the {Robot} (path parameter)
  #   - barcode: the barcode of the target plate (query parameter)
  #   - pick_number: the pick number when multiple source plates are used (query parameter)
  #   - generator_id: the id of the {RobotProperty} to use (query parameter)
  #
  # @return [void]
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

  # Retrieves the required generator_id parameter from query parameters.
  #
  # generator_id is the id of the requested robot generation behaviour {RobotProperty}
  # @raise [ActionController::ParameterMissing] if the parameter is missing
  # @return [Integer] the generator id
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
