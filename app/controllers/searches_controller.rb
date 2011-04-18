class SearchesController < ApplicationController
  include Informatics::Globals
  include SearchBehaviour
  alias_method(:index, :search)

private

  SEARCHABLE_CLASSES = [ Project, Study, Sample, Item, Asset, AssetGroup, Request, Supplier ]
  def searchable_classes
    SEARCHABLE_CLASSES
  end
end
