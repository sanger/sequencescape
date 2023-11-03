# frozen_string_literal: true
class Studies::SamplesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    @study = Study.find(params[:study_id])
    @samples = @study.samples.order(:created_at)

    respond_to do |format|
      format.html { @samples = @samples.paginate(page: params[:page], per_page: 384) }
      format.json { render json: @samples.to_json }
      format.xml { render xml: @samples.to_xml }
    end
  end
end
