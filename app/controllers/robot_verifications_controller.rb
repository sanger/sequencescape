# frozen_string_literal: true
class RobotVerificationsController < ApplicationController
  before_action :find_barcodes, only: :submission

  # Step 1: Renders a form asking for user barcode, batch barcode, robot barcode and destination plate barcode
  def index; end

  # Step 2: Renders the bed verification form, in which the user is expected to scan in all beds and plates
  #         This is generated based on the information provided in step 1.
  # rubocop:todo Metrics/MethodLength
  def submission # rubocop:todo Metrics/AbcSize
    errors = []

    if @robot.nil?
      errors << "Could not find robot #{barcode_hash[:robot_barcode]}"
    else
      @robot_verification = @robot.verification_behaviour
      @robot_verification.validate_barcode_params(barcode_hash) { |message| errors.push(message) }
    end

    if errors.empty?
      @pick_number = Batch.extract_pick_number(barcode_hash[:batch_barcode])
      @dest_plates, @source_plates, @ctrl_plates =
        @robot.pick_number_to_expected_layout(@batch, barcode_hash[:destination_plate_barcode])[@pick_number]
    else
      flash[:error] = errors
      redirect_to action: :index
    end
  end

  # rubocop:enable Metrics/MethodLength

  # Step 3: Receives the submission form and checks if it is valid. In the event it is valid
  #         provides a link to download the gwl/csv driver file for the robot. Otherwise
  #         redirects the user back to step 1 with an error message.
  def download # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @robot = Robot.find(params[:robot_id])
    @robot_verification = @robot.verification_behaviour

    if @robot_verification.valid_submission?(params)
      @robot_verification.record_plate_types(params[:plate_types])
      @batch = Batch.find(params[:batch_id])
      @batch.robot_verified!(params[:user_id])
      @destination_plate_id = Plate.find_from_barcode(params[:destination_plate_barcodes].keys.first).human_barcode
      @pick_number = params[:pick_number]
    else
      flash[:error] = "Error: #{@robot_verification.errors.join('; ')}"
      redirect_to action: :index
    end
  end

  def find_barcodes
    @robot = Robot.find_from_barcode(barcode_hash[:robot_barcode])
    @batch = Batch.find_from_barcode(barcode_hash[:batch_barcode])
    @user = User.find_with_barcode_or_swipecard_code(barcode_hash[:user_barcode])
  end

  def barcode_hash
    params.require(:barcodes)
  end
end
