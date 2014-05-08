class GelsController < ApplicationController
  before_filter :slf_gel_login_required

  def index
    # TODO: if a plate has a working dilution plate and it has a gel dilution plate, display:
    @gel_plates = GelDilutionPlate.paginate(:page => params[:page], :order => 'id DESC')
    @plates     = @gel_plates.map(&:stock_plate).compact
  end

  def find
  end

  def lookup
    @plate = Plate.find_by_barcode_and_barcode_prefix_id(params[:barcode], BarcodePrefix.find_by_prefix(Plate.prefix))
    if !@plate
      flash[:error] = "plate not found"
      render :action => :find
      return
    end

    render :action => :show
  end

  def show
    @plate = Plate.find(params[:id])
  end

  def update
    ActiveRecord::Base.transaction do
      params[:wells].keys.each do |well_id|
        well = Well.find(well_id)
        well.well_attribute.update_attributes!( :gel_pass => params[:wells][well_id][:qc_state])
        well.events.create_gel_qc!(params[:wells][well_id][:qc_state], current_user)
      end
      Plate.find(params[:id]).events.create_gel_qc!('', current_user)
    end
    flash[:notice] = "Gel results for plate updated"
    redirect_to :action => :index
  end
end
