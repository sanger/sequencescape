# frozen_string_literal: true
class Batches::RequestsController < ApplicationController # rubocop:todo Style/Documentation
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!

  def index
    requests = Batch.find(params[:batch_id]).requests
    respond_to { |format| format.xml { render xml: requests.to_xml } }
  end
end
