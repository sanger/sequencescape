class SearchesController < ApplicationController
  include Informatics::Globals
  include SearchBehaviour
  alias_method(:index, :search)

private

  # SEARCHABLE_CLASSES = [ Project, Study, Sample, Asset, AssetGroup, Request, Supplier ]
  def searchable_classes
    params[:type].blank? ? global_searchable_classes : [global_searchable_classes.detect {|klass| klass.name == params[:type] }]
  end


  def extended
    false
  end
end
