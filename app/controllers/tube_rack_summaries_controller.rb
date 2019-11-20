class TubeRackSummariesController < ApplicationController
  before_action :login_required

  def show
    @tube_rack = TubeRack.find_from_any_barcode(params[:id])
    raise ActiveRecord::RecordNotFound if @tube_rack.nil?
  end

end
