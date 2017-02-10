# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class PlateSummariesController < ApplicationController
  before_action :login_required

  def index
    @plates = Plate.source_plates.with_descendants_owned_by(current_user).order('assets.id desc').page(params[:page])
  end

  def show
    @plate = Plate.find_from_any_barcode(params[:id])
    raise ActiveRecord::RecordNotFound if @plate.nil?
    @custom_metadatum_collection = @plate.custom_metadatum_collection || NullCustomMetadatumCollection.new
    @sequencing_batches = @plate.descendant_lanes.include_creation_batches.map(&:creation_batches).flatten.uniq
  end

  def search
    candidate_plate = Plate.find_from_any_barcode(params[:plate_barcode])
    if candidate_plate.nil? || candidate_plate.source_plate.nil?
      redirect_to :back, flash: { error: "No suitable plates found for barcode #{params[:plate_barcode]}" }
    else
      redirect_to plate_summary_path(candidate_plate.source_plate.sanger_human_barcode)
    end
  end
end
