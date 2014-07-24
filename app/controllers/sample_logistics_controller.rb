class SampleLogisticsController < ApplicationController
  before_filter :slf_gel_login_required, :only => [:index, :qc_overview]

  def qc_overview
    @stock_plates = Plate.qc_started_plates.paginate :page => params[:page], :per_page => 500
  end
end
