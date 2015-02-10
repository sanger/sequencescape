#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2014 Genome Research Ltd.
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

  def extended
    true
  end
end
