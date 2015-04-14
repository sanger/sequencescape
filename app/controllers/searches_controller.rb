#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
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
