# frozen_string_literal: true
class Studies::EventsController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    @study = Study.find(params[:study_id])
    @events = @study.events.order(:created_at)
  end
end
