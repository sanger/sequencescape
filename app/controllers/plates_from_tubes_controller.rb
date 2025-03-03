# frozen_string_literal: true
class PlatesFromTubesController < ApplicationController
  before_action :set_barcode_printers, only: %i[new create]
  before_action :set_plate_creators, only: %i[new create]
  before_action :find_plate_creator, only: %i[create]

  PLATE_PURPOSES = ['Stock Plate', 'scRNA Stock Plate'].freeze

  def new
    respond_to do |format|
      format.html
      format.xml { render xml: @plate }
      format.json { render json: @plate }
    end
  end

  def create
    transfer_tubes_to_plate
  end

  private

  def valid_number_of_plates(tube_barcodes)
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
      if params[:plates_from_tubes][:plate_creator] == 'Stock Plate'
        [@plate_creators.find { |plate_creator| plate_creator.name == 'Stock Plate' }]
      elsif params[:plates_from_tubes][:plate_creator] == 'RNA Stock Plate'
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

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def transfer_tubes_to_plate
    @found_tubes ||= []
    source_tube_barcodes = params[:plates_from_tubes][:source_tubes].split(/[\s,]+/)
    unless valid_number_of_plates(source_tube_barcodes)
      flash.now[:error] = 'Number of tubes must be less than or equal to the number of wells in the plate(s)'
      return
    end
    # TODO: Optimise this to use a single query
    source_tube_barcodes.each do |tube_barcode|
      tube = Tube.find_by_barcode(tube_barcode)
      if tube.nil?
        flash[:error] = "Tube with barcode #{tube_barcode} not found"
        break
      end
      @found_tubes << tube
    end
    @created_plates = []
    @plate_creator.each { |creator| creator.create_plates_from_tubes(@found_tubes.dup, @created_plates) }

    respond_to do |format|
      flash.now[:notice] = 'Created plates successfully'
      format.html { render(new_plates_from_tube_path) }
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
