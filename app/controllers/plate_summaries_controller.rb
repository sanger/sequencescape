# frozen_string_literal: true
class PlateSummariesController < ApplicationController
  before_action :login_required

  def index
    @plates = Plate.source_plates.with_descendants_owned_by(current_user).order(id: :desc).page(params[:page])
  end

  def show
    @plate = Plate.find_from_any_barcode(params[:id])
    raise ActiveRecord::RecordNotFound if @plate.nil?

    @custom_metadatum_collection = @plate.custom_metadatum_collection || NullCustomMetadatumCollection.new
    @sequencing_batches = @plate.descendant_lanes.include_creation_batches.map(&:creation_batches).flatten.uniq
  end

  def search # rubocop:todo Metrics/AbcSize
    candidate_plate = Plate.find_from_any_barcode(params[:plate_barcode])
    @barcode = params[:plate_barcode]
    @plates = candidate_plate&.source_plates

    if @plates.blank?
      redirect_back_or_to root_path, flash: {
        error: "No suitable plates found for barcode #{params[:plate_barcode]}"
      }
    elsif @plates.one?
      redirect_to plate_summary_path(@plates.first.human_barcode)
    else
      render :search
    end
  end
end
