# frozen_string_literal: true

# The PlatesFromTubesController handles the creation of plates from tubes.
# It provides actions to display the form for creating plates and to process
# the form submission.
#
# The interface for this controller is through the endpoint /plates/from_tubes.
#
# Actions:
# - new: Renders the form for creating plates from tubes.
# - create: Processes the form submission and creates plates from the provided tubes.
#
# Before Actions:
# - set_barcode_printers: Sets the available barcode printers.
# - set_plate_creators: Sets the available plate creators.
# - find_plate_creator: Finds the plate creator based on the user's selection.
# - clear_flashes: Clears any flash messages.
#
# Constants:
# - VIEW_PATH: The path to the view template for rendering the form.
#
# rubocop:todo Metrics/ClassLength
class PlatesFromTubesController < ApplicationController
  before_action :set_barcode_printers, only: %i[new create]
  before_action :set_plate_creators, only: %i[new create]
  before_action :find_plate_creator, only: %i[create]
  before_action :clear_flashes

  VIEW_PATH = 'plates_from_tubes/new'

  def new
    respond_to { |format| format.html { render VIEW_PATH } }
  end

  def create
    barcode_printer = BarcodePrinter.find(params[:plates_from_tubes][:barcode_printer])
    scanned_user = User.find_with_barcode_or_swipecard_code(params[:plates_from_tubes][:user_barcode])
    if scanned_user.nil?
      respond_to do |format|
        handle_invalid_user
        format.html { render(VIEW_PATH) }
      end
      return
    end
    transfer_tubes_to_plate(scanned_user, barcode_printer)
  end

  private

  def clear_flashes
    flash.clear
  end

  def valid_number_of_tubes?(tube_barcodes)
    tube_barcodes.size <= @max_wells
  end

  def find_duplicate_tubes(tube_barcodes)
    tube_barcodes.group_by { |e| e }.select { |_, v| v.size > 1 }.keys
  end

  def set_plate_creators
    @plate_creators =
      Plate::Creator.where(
        name: Rails.application.config.plates_from_tubes_config[:plate_creator_names_for_creating_from_tubes]
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
      elsif params[:plates_from_tubes][:plate_type].to_s == 'Stock RNA Plate'
        [@plate_creators.find { |plate_creator| plate_creator.name == 'Stock RNA Plate' }]
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
  # This method orchestrates the process of transferring tubes to a plate and creating plates
  # based on the provided source tube barcodes. It performs several validation steps to ensure
  # the integrity of the data and handles errors gracefully. If all validations pass, it creates
  # plates and handles the success or failure of the operation.
  #
  # @param [User] scanned_user The user who scanned the tubes.
  # @param [BarcodePrinter] barcode_printer The barcode printer to use for printing plate barcodes.
  # @return [void]
  #
  # Steps:
  # 1. Extracts source tube barcodes from the request parameters.
  # 2. Validates the number of tubes against the maximum allowed wells.
  # 3. Checks for duplicate tube barcodes.
  # 4. Finds the tubes in the database based on the provided barcodes.
  # 5. Validates that all provided barcodes correspond to existing tubes.
  # 6. Attempts to create plates using the found tubes. If successful, it handles the success case.
  #    If an error occurs during plate creation, it handles the error appropriately.
  #
  # Error Handling:
  # - If the number of tubes exceeds the maximum allowed, it renders an error message.
  # - If duplicate tube barcodes are found, it renders an error message.
  # - If any tube barcodes are missing in the database, it renders an error message.
  # - If an ActiveRecord error occurs during plate creation, it renders an appropriate error message.
  #
  # Example:
  #   transfer_tubes_to_plate(scanned_user, barcode_printer)
  # rubocop:todo Metrics/MethodLength
  def transfer_tubes_to_plate(scanned_user, barcode_printer)
    source_tube_barcodes = extract_source_tube_barcodes
    return unless validate_tube_count?(source_tube_barcodes)
    return unless validate_duplicate_tubes?(source_tube_barcodes)
    found_tubes = find_tubes(source_tube_barcodes)
    return unless validate_missing_tubes?(found_tubes, source_tube_barcodes)
    begin
      create_plates(scanned_user, barcode_printer, found_tubes)
      handle_successful_creation
    rescue ActiveRecord::ActiveRecordError => e
      if e.message.include?('No change')
        handle_error('Error creating plates because the server detected duplicate barcodes.')
      else
        handle_error('Error creating plates')
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def handle_successful_creation
    respond_to do |format|
      flash.now[:notice] = 'Created plates successfully'
      @plate_creator.each { |creator| flash[:warning] = creator.warnings if creator.warnings.present? }
      format.html { render(VIEW_PATH) }
    end
  end

  def handle_error(message)
    respond_to do |format|
      flash.now[:error] = message
      format.html { render(VIEW_PATH) }
    end
  end

  # Validates the number of tubes against the maximum allowed wells.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [Boolean] Returns true if the number of tubes is valid, false otherwise.
  def validate_tube_count?(source_tube_barcodes)
    unless valid_number_of_tubes?(source_tube_barcodes)
      respond_to do |format|
        handle_invalid_tube_count
        format.html { render(VIEW_PATH) }
      end
      return false
    end
    true
  end

  # Validates if there are any duplicate tubes in the provided barcodes.
  #
  # @param [Array<String>] source_tube_barcodes An array of source tube barcodes.
  # @return [Boolean] Returns true if there are no duplicate tubes, false otherwise.
  def validate_duplicate_tubes?(source_tube_barcodes)
    duplicate_tubes = find_duplicate_tubes(source_tube_barcodes)
    if duplicate_tubes.present?
      respond_to do |format|
        handle_duplicate_tubes(duplicate_tubes)
        format.html { render(VIEW_PATH) }
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
  def validate_missing_tubes?(found_tubes, source_tube_barcodes)
    if found_tubes.size != source_tube_barcodes.size
      respond_to { |format| format.html { render(VIEW_PATH) } }
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
  # rubocop: enable Rails/ActionControllerFlashBeforeRender

  # Extracts source tube barcodes from the parameters.
  #
  # @return [Array<String>] An array of source tube barcodes.
  def extract_source_tube_barcodes
    params[:plates_from_tubes][:source_tubes]&.split(/[\s,]+/)&.map(&:strip) || []
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
    ActiveRecord::Base.transaction do
      @plate_creator.each do |creator|
        creator.create_plates_from_tubes!(found_tubes.dup, @created_plates, scanned_user, barcode_printer)
      end
    end
    return unless params[:plates_from_tubes][:create_asset_group] == 'Yes'
    # The logic is the same for all plate creators, so we can just use the first one
    @asset_groups << @plate_creator.first.create_asset_group(@created_plates)
  end
end
# rubocop:enable Metrics/ClassLength
