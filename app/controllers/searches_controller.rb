# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

class SearchesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  include Informatics::Globals
  include SearchBehaviour
  alias_method(:index, :search)

private

  # SEARCHABLE_CLASSES = [ Project, Study, Sample, Asset, AssetGroup, Request, Supplier ]
  def searchable_classes
    params[:type].blank? ? global_searchable_classes : [global_searchable_classes.detect { |klass| klass.name == params[:type] }]
  end

  def extended
    false
  end
end
