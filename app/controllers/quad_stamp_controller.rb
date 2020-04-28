

class QuadStampController < ApplicationController
  before_action :set_plate_purposes, only: [:new, :create]
  before_action :set_barcode_printers, only: [:new, :create]

  # TODO: validation that at least one quadrant is filled
  # TODO: validation that all sources are sane type (plate OR tube rack)
  # TODO: validation that all sources exist

  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @user = User.find_with_barcode_or_swipecard_code(params[:quad_creator][:user_barcode])
    @target_purpose = Purpose.find(params[:quad_creator][:target_purpose_id])
    @printer_id = params[:quad_creator][:barcode_printer]
    
    # puts "DEBUG: @user = #{@user}"
    # puts "DEBUG: @target_purpose = #{@target_purpose}"
    # puts "DEBUG: @printer_id = #{@printer_id}"
    # Rails.logger.debug parent_barcodes
    @quad_creator = Plate::QuadCreator.new(parent_barcodes: parent_barcodes, target_purpose: @target_purpose, user: @user)

    if @quad_creator.save
      # TODO: print the target barcode (2 copies?)
      redirect_to plates_path(@quad_creator.target_plate.id), notice: "A new #{@target_purpose.name} plate was created and labels printed"
    else
      errors = @quad_creator.errors.full_messages.join(';').truncate(500, separator: ' ')
      redirect_to quad_stamp_path, alert: "Failed to create plate of type #{target_purpose}: #{errors}"
    end
  end

  private

  # Selects the appropriate plate purposes for the user to choose from.
  # In this case they must be 384-well stock plates.
  def set_plate_purposes
    @plate_purposes = Purpose.order(:name).where(size: 384, stock_plate: true).order('name asc')
  end

  # Selects barcode printers for the user to choose from.
  # Attempts to first get 384-well label specific printers (384-well plates take narrow 6mm labels)
  def set_barcode_printers
    @barcode_printers = BarcodePrinterType384DoublePlate.first.barcode_printers.order('name asc')
    @barcode_printers = BarcodePrinter.order('name asc') if @barcode_printers.blank?
  end

  # def lookup_source(source_barcode, quad_name)
  #   source_labware = Labware.find_from_barcode(source_barcode)
  #   if @source_labware.present?
  #     @parents_hash[:quad_name] = @source_labware
  #   else
  #     errors << "Could not find a matching labware for barcode #{source_barcode}"
  #   end
  # end

  def parent_barcodes
    params.require(:quad_creator)
          .require(:parent_barcodes)
          .reject { |key, barcode| barcode.blank? }
  end
end
