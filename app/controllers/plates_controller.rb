# frozen_string_literal: true
class PlatesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :login_required, except: [:fluidigm_file]

  before_action :set_plate_creators, only: %i[new create]
  before_action :set_barcode_printers, only: %i[new create]

  def show
    @plate = Plate.find(params[:id])
    @page_name = @plate.name
  end

  def new
    respond_to do |format|
      format.html
      format.xml { render xml: @plate }
      format.json { render json: @plate }
    end
  end

  # rubocop:todo Metrics/MethodLength
  def create # rubocop:todo Metrics/AbcSize
    @creator = plate_creator = Plate::Creator.find(params[:plates][:creator_id])
    barcode_printer = BarcodePrinter.find(params[:plates][:barcode_printer])
    source_plate_barcodes = params[:plates][:source_plates]
    create_asset_group = params[:plates][:create_asset_group] == 'Yes'

    scanned_user = User.find_with_barcode_or_swipecard_code(params[:plates][:user_barcode])

    respond_to do |format|
      if scanned_user.nil?
        flash[:error] = 'Please scan your user barcode'
      elsif tube_rack_sources?
        plate_creator.create_plates_from_tube_racks!(tube_racks, barcode_printer, scanned_user, create_asset_group)
      else
        plate_creator.execute(
          source_plate_barcodes,
          barcode_printer,
          scanned_user,
          create_asset_group,
          Plate::CreatorParameters.new(params[:plates])
        )
      end
      flash[:notice] = 'Created plates successfully'
      flash[:warning] = plate_creator.warnings if plate_creator.warnings.present?
      format.html { render(new_plate_path) }
    end
  rescue StandardError => e
    respond_to do |format|
      flash[:error] = e.message
      format.html { render(new_plate_path) }
    end
  end

  # rubocop:enable Metrics/MethodLength

  def set_plate_creators
    @plate_creators = Plate::Creator.order(:name)
  end

  def set_barcode_printers
    @barcode_printers = BarcodePrinterType96Plate.first.barcode_printers
    @barcode_printers = BarcodePrinter.order('name asc') if @barcode_printers.blank?
  end

  def tube_rack_barcodes
    return [] unless params.dig(:plates, :source_plates)

    params[:plates][:source_plates].split(/[\s,]+/)
  end

  def tube_rack_sources?
    return false if tube_rack_barcodes.empty?

    tube_racks.count == tube_rack_barcodes.length
  end

  def tube_racks
    @tube_racks ||= TubeRack.joins(:barcodes).where(barcodes: { barcode: tube_rack_barcodes })
  end

  def to_sample_tubes
    @barcode_printers = BarcodePrinter.all
    @studies = Study.alphabetical
  end

  def create_sample_tubes # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    barcode_printer = BarcodePrinter.find(params[:plates][:barcode_printer])
    barcode_array = params[:plates][:source_plates].scan(/\w+/)
    plates = Plate.with_barcode(barcode_array)
    study = Study.find(params[:plates][:study])

    respond_to do |format|
      asset_group =
        Plate::SampleTubeFactory.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, study)
      if asset_group
        flash[:notice] = 'Created tubes and printed barcodes'

        # makes request properties partial show
        format.html { redirect_to(new_submission_path(study_id: asset_group.study.id)) }
        format.xml { render xml: asset_group, status: :created }
        format.json { render json: asset_group, status: :created }
      else
        flash[:error] = 'Failed to create sample tubes'
        format.html { redirect_to(to_sample_tubes_plates_path) }
        format.xml { render xml: flash.to_xml, status: :unprocessable_entity }
        format.json { render json: flash.to_json, status: :unprocessable_entity }
      end
    end
  end

  def fluidigm_file
    if logged_in?
      @plate = Plate.includes(wells: [{ samples: :sample_metadata }, :map]).find(params[:id])
      @parents = @plate.parents
      respond_to { |format| format.csv { render csv: @plate, content_type: 'text/csv' } }
    end
  end
end
