# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Api::RequestsController < Api::BaseController
  self.model_class = Request

  before_action :prepare_object, only: [:show, :update, :destroy]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = if not params[:sample_tube_id].blank?
      ::SampleTube.find(params[:sample_tube_id]).requests
               elsif not params[:library_tube_id].blank?
      ::LibraryTube.find(params[:library_tube_id]).requests
               else
      Request.including_associations_for_json
               end
  end
end
