# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
class PlatesFromTubesController < ApplicationController
  before_action :set_barcode_printers, only: %i[new create]
  before_action :set_plate_creators, only: %i[new create]
  before_action :find_plate_creator, only: %i[create]
  before_action :clear_flashes

  def new
    respond_to { |format| format.html }
  end

  def create
    barcode_printer = BarcodePrinter.find(params[:plates_from_tubes][:barcode_printer])
    transfer_tubes_to_plate(params[:plates_from_tubes][:user_barcode], barcode_printer)
  end

  private

  def clear_flashes
    flash.clear
  end

  def valid_number_of_tubes(tube_barcodes)
    tube_barcodes.size <= @max_wells
  end

  def find_duplicate_tubes(tube_barcodes)
    tube_barcodes.group_by { |e| e }.select { |_, v| v.size > 1 }.keys
  end

  def set_plate_creators
    @plate_creators =
      Plate::Creator.where(
        name: configatron.fetch(:plate_purposes_to_create_from_tubes, ['Stock Plate', 'scRNA Stock Plate'])
      )
  end

  # This is using the plate_type parameter coming out of the form. The HTML component behind this is ab
  # input radio button.
  #
  # This function sets the plate creator based on the user's selection on the radio buttons.
  #
  # If the user selects 'Stock Plate', then the plate creator is set to StockPlateCreator.
  # If the user selects 'RNA Stock Plate', then the plate creator is set to RnaStockPlateCreator.
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
  # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
  def transfer_tubes_to_plate(user_barcode, barcode_printer)
    scanned_user = User.find_with_barcode_or_swipecard_code(user_barcode)
    if scanned_user.nil?
      respond_to do |format|
        handle_invalid_user
        format.html { render(new_plates_from_tube_path) }
      end
      return
    end
    source_tube_barcodes = extract_source_tube_barcodes
    return unless validate_tube_count(source_tube_barcodes)
    return unless validate_duplicate_tubes(source_tube_barcodes)
    found_tubes = find_tubes(source_tube_barcodes)
    return unless validate_missing_tubes(found_tubes, source_tube_barcodes)
    create_plates(scanned_user, barcode_printer, found_tubes)
    respond_to do |format|
      flash.now[:notice] = 'Created plates successfully'
      @plate_creator.each { |creator| flash[:warning] = creator.warnings if creator.warnings.present? }
      format.html { render(new_plates_from_tube_path) }
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  # Validates the number of tubes against the maximum allowed wells.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [Boolean] Returns true if the number of tubes is valid, false otherwise.
  def validate_tube_count(source_tube_barcodes)
    unless valid_number_of_tubes(source_tube_barcodes)
      respond_to do |format|
        handle_invalid_tube_count
        format.html { render(new_plates_from_tube_path) }
        return false
      end
    end
    true
  end

  # Validates if there are any duplicate tubes in the provided barcodes.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [Boolean] Returns true if there are no duplicate tubes, false otherwise.
  def validate_duplicate_tubes(source_tube_barcodes)
    duplicate_tubes = find_duplicate_tubes(source_tube_barcodes)
    if duplicate_tubes.present?
      respond_to do |format|
        handle_duplicate_tubes(duplicate_tubes)
        format.html { render(new_plates_from_tube_path) }
      end
      return false
    end
    true
  end

  # Validates if all the found tubes match the provided barcodes.
  #
  # @param [Array<Tube>] found_tubes An array of found tubes.
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [Boolean] Returns true if all tubes are found, false otherwise.
  def validate_missing_tubes(found_tubes, source_tube_barcodes)
    if found_tubes.size != source_tube_barcodes.size
      respond_to do |format|
        handle_missing_tubes
        format.html { render(new_plates_from_tube_path) }
      end
      return false
    end
    true
  end

  # rubocop: todo Rails/ActionControllerFlashBeforeRender
  def handle_invalid_user
    flash[:error] = 'Please enter a valid user barcode'
  end

  def handle_invalid_tube_count
    flash[:error] = 'Number of tubes exceeds the maximum number of wells'
  end

  def handle_duplicate_tubes(duplicate_tubes)
    flash[:error] = "Duplicate tubes found: #{duplicate_tubes.join(', ')}"
  end

  def handle_missing_tubes
    flash[:error] = 'Some tubes were not found'
  end
  # rubocop: enable Rails/ActionControllerFlashBeforeRender

  # Extracts source tube barcodes from the parameters.
  #
  # @return [Array<String>] An array of source tube barcodes.
  def extract_source_tube_barcodes
    params[:plates_from_tubes][:source_tubes].split(/[\s,]+/)
  end

  # Finds tubes based on the provided barcodes and stores them in found_tubes.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [void]
  def find_tubes(source_tube_barcodes)
    found_tubes = []
    source_tube_barcodes.each do |tube_barcode|
      tube = Tube.find_by_barcode(tube_barcode)
      if tube.nil?
        flash[:error] = "Tube with barcode #{tube_barcode} not found"
        break
      end
      found_tubes << tube
    end
    found_tubes
  end

  # Creates plates from the found tubes and stores them in @created_plates.
  # Creates an asset group if the user selects 'Yes' for creating an asset group.
  #
  # @param [User] scanned_user The user who scanned the tubes.
  # @param [BarcodePrinter] barcode_printer The barcode printer to use.
  # @return [void]
  def create_plates(scanned_user, barcode_printer, found_tubes)
    @created_plates = []
    @asset_groups = []
    @plate_creator.each do |creator|
      creator.create_plates_from_tubes(found_tubes.dup, @created_plates, scanned_user, barcode_printer)
    end
    return unless params[:plates_from_tubes][:create_asset_group] == 'Yes'
    # The logic is the same for all plate creators, so we can just use the first one
    @asset_groups << @plate_creator.first.create_asset_group(@created_plates)
  end
end
# rubocop:enable Metrics/ClassLength
