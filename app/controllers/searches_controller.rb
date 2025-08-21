# frozen_string_literal: true
class SearchesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  include Informatics::Globals
  include SearchBehaviour

  alias index search

  private

  # SEARCHABLE_CLASSES = [ Project, Study, Sample, Labware, AssetGroup, Request, Supplier ]
  def searchable_classes
    if params[:type].blank?
      global_searchable_classes
    else
      [global_searchable_classes.detect { |klass| klass.name == params[:type] }]
    end
  end
end
