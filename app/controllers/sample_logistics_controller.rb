class SampleLogisticsController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :slf_gel_login_required, only: [:index, :qc_overview]

  def qc_overview
    @stock_plates = Plate.qc_started_plates.paginate page: params[:page], per_page: 500
  end
end
