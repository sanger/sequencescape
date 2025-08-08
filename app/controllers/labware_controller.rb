# frozen_string_literal: true

# Handles viewing {Labware} information
# @see Labware
class LabwareController < ApplicationController # rubocop:todo Metrics/ClassLength
  include RetentionInstructionHelper

  before_action :discover_asset, only: %i[show edit update summary print_assets print history retention_instruction]

  def index # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    if params[:study_id]
      @study = Study.find(params[:study_id])
      @assets = @study.assets_through_aliquots.order(:name).page(params[:page])
    else
      @assets = Labware.page(params[:page])
    end

    respond_to do |format|
      format.html
      if params[:study_id]
        format.xml { render xml: Study.find(params[:study_id]).assets_through_requests.to_xml }
      elsif params[:sample_id]
        format.xml { render xml: Sample.find(params[:sample_id]).assets.to_xml }
      elsif params[:asset_id]
        @asset = Labware.find(params[:asset_id])
        format.xml do
          render xml: [{ 'relations' => { 'parents' => @asset.parents, 'children' => @asset.children } }].to_xml
        end
      end
    end
  end

  def show
    @page_name = @asset.display_name
    @source_plates = @asset.source_plates
    respond_to do |format|
      format.html { @aliquots = @asset.aliquots.include_summary.paginate(page: params[:page], per_page: 384) }
      format.xml
      format.json { render json: @asset }
    end
  end

  def edit
    @valid_purposes_options = @asset.compatible_purposes.pluck(:name, :id)
  end

  def retention_instruction
    @retention_instruction_options = retention_instruction_option_for_select
  end

  def history
    respond_to do |format|
      format.html
      format.xml { @request.events.to_xml }
      format.json { @request.events.to_json }
    end
  end

  def update # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    respond_to do |format|
      params_hash = params.to_unsafe_h
      current_retention_instruction = @asset.retention_instruction
      if @asset.update(labware_params.merge(params_hash.fetch(:lane, {})))
        if params_hash[:labware].key?(:retention_instruction) &&
            current_retention_instruction != @asset.retention_instruction
          EventFactory.record_retention_instruction_updates(@asset, current_user, current_retention_instruction)
        end
        flash[:notice] = find_flash(params_hash)
        if params[:lab_view]
          format.html { redirect_to(action: :lab_view, barcode: @asset.human_barcode) }
        else
          format.html { redirect_to(action: :show, id: @asset.id) }
          format.xml { head :ok }
        end
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @asset.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @asset.destroy

    respond_to do |format|
      format.html { redirect_to(assets_url) }
      format.xml { head :ok }
    end
  end

  def summary
    @summary = UiHelper::Summary.new(per_page: 25, page: params[:page])
    @summary.load_asset(@asset)
  end

  def print
    if @asset.printable?
      @printable = @asset.printable_target
      @direct_printing = (@asset.printable_target == @asset)
    else
      flash[:error] = "#{@asset.display_name} does not have a barcode so a label can not be printed."
      redirect_to labware_path(@asset)
    end
  end

  def print_labels
    print_job =
      LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::AssetRedirect, printables: params[:printables])
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end

    redirect_to phi_x_url
  end

  def print_assets
    print_job = LabelPrinter::PrintJob.new(params[:printer], LabelPrinter::Label::AssetRedirect, printables: @asset)
    if print_job.execute
      flash[:notice] = print_job.success
    else
      flash[:error] = print_job.errors.full_messages.join('; ')
    end
    redirect_to labware_path(@asset)
  end

  def show_plate
    @asset = Plate.find(params[:id])
    @page_name = @asset.display_name
  end

  def lookup # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    return unless params[:asset] && params[:asset][:barcode]

    @assets = Labware.with_barcode(params[:asset][:barcode]).limit(50).page(params[:page])

    if @assets.size == 1
      redirect_to @assets.first
    elsif @assets.empty?
      flash.now[:error] = "No asset found with barcode #{params[:asset][:barcode]}"
      respond_to do |format|
        format.html { render action: 'lookup' }
        format.xml { render xml: @assets.to_xml }
      end
    else
      respond_to do |format|
        format.html { render action: 'index' }
        format.xml { render xml: @assets.to_xml }
      end
    end
  end

  def find_by_barcode
  end

  def lab_view
    barcode = params.fetch(:barcode, '').strip

    if barcode.blank?
      redirect_to action: 'find_by_barcode'
      nil
    else
      @asset = Labware.find_from_barcode(barcode)
      if @asset.nil?
        redirect_to action: 'find_by_barcode', error: "Unable to find anything with this barcode: #{barcode}"
      end
    end
  end

  private

  def labware_params
    permitted = %i[volume concentration retention_instruction]
    permitted << :name if can? :rename, Labware
    permitted << :plate_purpose_id if can? :change_purpose, Labware
    params.require(:labware).permit(permitted)
  end

  def discover_asset
    @asset = Labware.include_for_show.find(params[:id])
  end

  def find_flash(params_hash)
    if params_hash[:labware].key?(:retention_instruction)
      'Retention Instruction was successfully updated.'
    else
      'Labware was successfully updated.'
    end
  end
end
