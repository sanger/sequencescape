class RobotVerificationsController < ApplicationController
  before_filter :new_robot_verification

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
      redirect_to :action => :index
    end
  end

  def download
    if @robot_verification.valid_submission?(params)
      @robot_verification.set_plate_types(params[:source_plate_types])
      @batch = Batch.find(params[:batch_id])
      @destination_plate_id = Plate.with_machine_barcode(params[:destination_plate_barcodes].first.first).first.barcode
    else
      flash[:error] = "Error: Check everything again"
      redirect_to :action => :index
    end
  end

  def get_fields_and_check(barcode_hash)
    @batch = Batch.find_from_barcode(barcode_hash[:batch_barcode])
    @user = User.find_by_barcode(Barcode.barcode_to_human!(barcode_hash[:user_barcode], User.prefix))
    @all_labels = @robot_verification.expected_layout(@batch,barcode_hash[:destination_plate_barcode])
    @robot = Robot.find_from_barcode(barcode_hash[:robot_barcode])
  end

  def new_robot_verification
    @robot_verification = RobotVerification.new
  end

end
