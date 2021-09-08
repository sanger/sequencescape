# frozen_string_literal: true
class GelsController < ApplicationController # rubocop:todo Style/Documentation
  # JG 29/03/2019
  # The GelQC process is no longer actively performed, although we should be careful
  # of hiding access to historical data.

  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  authorize_resource :gels_controller

  def index
    # TODO: if a plate has a working dilution plate and it has a gel dilution plate, display:
    @gel_plates = GelDilutionPlate.page(params[:page]).order(id: :desc)
    @plates = @gel_plates.filter_map(&:stock_plate)
  end

  def find; end

  def lookup
    @plate = Plate.find_from_barcode([params[:barcode], "#{Plate.default_prefix}#{params[:barcode]}"])
    unless @plate
      flash[:error] = 'plate not found'
      render action: :find
      return
    end

    render action: :show
  end

  def show
    @plate = Plate.find(params[:id])
  end

  def update # rubocop:todo Metrics/AbcSize
    ActiveRecord::Base.transaction do
      params[:wells].keys.each do |well_id|
        well = Well.find(well_id)
        well.well_attribute.update!(gel_pass: params[:wells][well_id][:qc_state])
        well.events.create_gel_qc!(params[:wells][well_id][:qc_state], current_user)
      end
      Plate.find(params[:id]).events.create_gel_qc!('', current_user)
    end
    flash[:notice] = 'Gel results for plate updated'
    redirect_to action: :index
  end
end
