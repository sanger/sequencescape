# frozen_string_literal: true
class Samples::StudiesController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    studies = Sample.find(params[:sample_id]).studies
    respond_to { |format| format.xml { render xml: studies.to_xml } }
  end
end
