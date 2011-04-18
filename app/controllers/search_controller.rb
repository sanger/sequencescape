class SearchController < ApplicationController
  include SearchBehaviour
  alias_method(:new, :search)

  def index
    redirect_to :action => :new
  end

private

  SEARCHABLE_CLASSES = [ Batch, Asset ]
  def searchable_classes
    SEARCHABLE_CLASSES
  end
end
