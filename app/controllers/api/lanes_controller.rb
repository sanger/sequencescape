#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Api::LanesController < Api::AssetsController
  self.model_class = Lane

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::Lane.including_associations_for_json
    @context = ::LibraryTube.find(params[:library_tube_id]).children unless params[:library_tube_id].blank?
  end
end
