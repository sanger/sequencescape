# frozen_string_literal: true
# Handles transfer of 1-4 96 well plates or tube racks onto a single new
# 384 well plate
class QuadStampController < ApplicationController
  before_action :set_plate_purposes, only: %i[new create]
  before_action :set_barcode_printers, only: %i[new create]

  def new
    @quad_creator = Plate::QuadCreator.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @user = User.find_with_barcode_or_swipecard_code(params[:quad_creator][:user_barcode])
    @target_purpose = Purpose.find(params[:quad_creator][:target_purpose_id])
    @quad_creator =
      Plate::QuadCreator.new(parent_barcodes: parent_barcodes.to_hash, target_purpose: @target_purpose, user: @user)

    if @quad_creator.save
      print_labels
      redirect_to labware_path(@quad_creator.target_plate),
                  notice: "A new #{@target_purpose.name} plate was created and labels printed"
    else
      render :new
    end
  end

  private

  def print_labels # rubocop:todo Metrics/MethodLength
    print_job =
      LabelPrinter::PrintJob.new(
        params.dig(:barcode_printer, :name),
        LabelPrinter::Label::AssetRedirect,
        printables: @quad_creator.target_plate
      )
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
  end

  # Selects the appropriate plate purposes for the user to choose from.
  # In this case they must be 384-well stock plates.
  def set_plate_purposes
    @plate_purposes = Purpose.order(:name).where(size: 384, stock_plate: true).order(:name)
  end

  # Selects barcode printers for the user to choose from.
  # Attempts to first get 384-well label specific printers (384-well plates take narrow 6mm labels)
  def set_barcode_printers
    @barcode_printers =
      BarcodePrinter.where(barcode_printer_type_id: BarcodePrinterType384DoublePlate.all).order(:name)
    if @barcode_printers.blank?
      @barcode_printers = BarcodePrinter.where(barcode_printer_type_id: BarcodePrinterType96Plate.all).order(:name)
    end
  end

  def parent_barcodes
    params
      .require(:quad_creator)
      .require(:parent_barcodes)
      .permit(:quad_1, :quad_2, :quad_3, :quad_4)
      .reject { |_key, barcode| barcode.empty? }
  end
end
