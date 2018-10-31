class LabSearchesController < ApplicationController
  SEARCHABLE_CLASSES = [Batch, Asset]

  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  include SearchBehaviour
  alias_method(:new, :search)

  def index
    redirect_to action: :new
  end

  private

  def clazz_query(clazz, query)
    super.for_lab_searches_display
  end

  def searchable_classes
    SEARCHABLE_CLASSES
  end
end
