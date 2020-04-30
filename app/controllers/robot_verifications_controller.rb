class RobotVerificationsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :new_robot_verification

  def index
  end

  def submission
    barcode_hash = params[:barcodes]

    errors = []
    @robot_verification.validate_barcode_params(barcode_hash, &errors.method(:push))
    if errors.empty?
      get_fields_and_check(barcode_hash)
    else
      flash[:error] = errors
      redirect_to action: :index
    end
  end

  def download
    if @robot_verification.valid_submission?(params)
      @robot_verification.set_plate_types(params[:source_plate_types])
      @robot_verification.set_plate_types(params.fetch(:destination_plate_types, {}))
      @batch = Batch.find(params[:batch_id])
      @batch.robot_verified!(params[:user_id])
      @destination_plate_id = Plate.find_from_barcode(params[:destination_plate_barcodes].keys.first).human_barcode
    else
      flash[:error] = "Error: #{@robot_verification.errors.join('; ')}"
      redirect_to action: :index
    end
  end

  def get_fields_and_check(barcode_hash)
    @batch = Batch.find_from_barcode(barcode_hash[:batch_barcode])
    @user = User.find_with_barcode_or_swipecard_code(barcode_hash[:user_barcode])
    @all_labels = @robot_verification.expected_layout(@batch, barcode_hash[:destination_plate_barcode])
    @robot = Robot.find_from_barcode(barcode_hash[:robot_barcode])
  end

  def new_robot_verification
    @robot_verification = RobotVerification.new
  end
end
