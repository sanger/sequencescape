class Studies::Plates::WellsController < ApplicationController
  before_filter :discover_study, :discover_plate

  def index
    @wells = @plate.wells.paginate :page => params[:page], :order => 'created_at DESC'
  end

  def new

  end

  private
  def discover_plate
    @plate = Plate.find(params[:plate_id])
  end

  def discover_study
    @study = Study.find(params[:study_id])
  end
end
