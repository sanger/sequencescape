# frozen_string_literal: true
class PlatesFromTubesController < ApplicationController
  before_action :set_barcode_printers, only: %i[new create]
  before_action :set_plate_creators, only: %i[new create]
  before_action :find_plate_creator, only: %i[create]

  PLATE_PURPOSES = ['Stock Plate', 'scRNA Stock Plate'].freeze

  def new
    respond_to { |format| format.html }
  end

  def create
    scanned_user = User.find_with_barcode_or_swipecard_code(params[:plates_from_tubes][:user_barcode])
    barcode_printer = BarcodePrinter.find(params[:plates_from_tubes][:barcode_printer])
    transfer_tubes_to_plate(scanned_user, barcode_printer)
  end

  private

  def valid_number_of_tubes(tube_barcodes)
    tube_barcodes.size <= @max_wells
  end

  def set_plate_creators
    @plate_creators = Plate::Creator.where(name: PLATE_PURPOSES)
  end

  # Set the plate creator based on the user's selection on the radio buttons
  # If the user selects 'Stock Plate', then the plate creator is set to StockPlateCreator
  # If the user selects 'RNA Stock Plate', then the plate creator is set to RnaStockPlateCreator
  # If the user selects 'All of the above', then the plate creators are both StockPlateCreator and RnaStockPlateCreator
  #
  # rubocop:todo Metrics/AbcSize
  def find_plate_creator
    @plate_creator =
      if params[:plates_from_tubes][:plate_type].to_s == 'Stock Plate'
        [@plate_creators.find { |plate_creator| plate_creator.name == 'Stock Plate' }]
      elsif params[:plates_from_tubes][:plate_type].to_s == 'RNA Stock Plate'
        [@plate_creators.find { |plate_creator| plate_creator.name == 'scRNA Stock Plate' }]
      else
        @plate_creators
      end
    @max_wells = @plate_creator.map { |pc| pc.plate_purposes.first.size }.max
  end
  # rubocop:enable Metrics/AbcSize

  # Set the barcode printers based on the user's selection on the radio buttons
  def set_barcode_printers
    @barcode_printers = BarcodePrinterType96Plate.first.barcode_printers
    @barcode_printers = BarcodePrinter.order('name asc') if @barcode_printers.blank?
  end

  # Transfers tubes to a plate and creates plates from the given tubes.
  #
  # @return [void]
  def transfer_tubes_to_plate(scanned_user, barcode_printer)
    @found_tubes ||= []
    source_tube_barcodes = extract_source_tube_barcodes
    unless valid_number_of_tubes(source_tube_barcodes)
      flash[:error] = 'Number of tubes exceeds the maximum number of wells'
      return
    end

    find_tubes(source_tube_barcodes)
    create_plates(scanned_user, barcode_printer)
    respond_with_success
  end

  # Extracts source tube barcodes from the parameters.
  #
  # @return [Array<String>] An array of source tube barcodes.
  def extract_source_tube_barcodes
    params[:plates_from_tubes][:source_tubes].split(/[\s,]+/)
  end

  # Finds tubes based on the provided barcodes and stores them in @found_tubes.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [void]
  def find_tubes(source_tube_barcodes)
    source_tube_barcodes.each do |tube_barcode|
      tube = Tube.find_by_barcode(tube_barcode)
      if tube.nil?
        flash[:error] = "Tube with barcode #{tube_barcode} not found"
        break
      end
      @found_tubes << tube
    end
    return unless @found_tubes.size != source_tube_barcodes.size
    flash.now[:warning] = 'Some tubes were not found. Please double-check the tube barcodes.'
  end

  # Creates plates from the found tubes and stores them in @created_plates.
  # Creates an asset group if the user selects 'Yes' for creating an asset group.
  #
  # @param [User] scanned_user The user who scanned the tubes.
  # @param [BarcodePrinter] barcode_printer The barcode printer to use.
  # @return [void]
  def create_plates(scanned_user, barcode_printer)
    @created_plates = []
    @asset_groups = []
    @plate_creator.each do |creator|
      creator.create_plates_from_tubes(@found_tubes.dup, @created_plates, scanned_user, barcode_printer)
    end
    return unless params[:plates_from_tubes][:create_asset_group] == 'Yes'
    # The logic is the same for all plate creators, so we can just use the first one
    @asset_groups << @plate_creator.first.create_asset_group(@created_plates)
  end

  # Responds with a success message and renders the new plates from tube path.
  #
  # @return [void]
  def respond_with_success
    respond_to do |format|
      flash.now[:notice] = 'Created plates successfully'
      @plate_creator.each { |creator| flash[:warning] = creator.warnings if creator.warnings.present? }
      format.html { render(new_plates_from_tube_path) }
    end
  end
end
