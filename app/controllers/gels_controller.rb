# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class GelsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :slf_gel_login_required

  def index
    # TODO: if a plate has a working dilution plate and it has a gel dilution plate, display:
    @gel_plates = GelDilutionPlate.page(params[:page]).order(id: :desc)
    @plates     = @gel_plates.map(&:stock_plate).compact
  end

  def find
  end

  def lookup
    @plate = Plate.find_by(barcode: params[:barcode], barcode_prefix_id: BarcodePrefix.find_by(prefix: Plate.prefix))
    if !@plate
      flash[:error] = 'plate not found'
      render action: :find
      return
    end

    render action: :show
  end

  def show
    @plate = Plate.find(params[:id])
  end

  def update
    ActiveRecord::Base.transaction do
      params[:wells].keys.each do |well_id|
        well = Well.find(well_id)
        well.well_attribute.update_attributes!(gel_pass: params[:wells][well_id][:qc_state])
        well.events.create_gel_qc!(params[:wells][well_id][:qc_state], current_user)
      end
      Plate.find(params[:id]).events.create_gel_qc!('', current_user)
    end
    flash[:notice] = 'Gel results for plate updated'
    redirect_to action: :index
  end
end
