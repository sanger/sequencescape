# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Api::SamplesController < Api::BaseController
  self.model_class = Sample

  before_action :prepare_object, only: [:show, :update, :destroy]
  before_action :prepare_list_context, only: [:index]

  def next_sanger_sample_id
    respond_to do |format|
      format.json { render json: SangerSampleId.create.id }
    end
  end

private

  def prepare_list_context
    @context = ::Sample.including_associations_for_json
    @context = ::Study.find(params[:study_id]).samples unless params[:study_id].blank?
  end
end
