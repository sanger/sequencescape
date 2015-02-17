#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class Api::AliquotsController < Api::BaseController
  self.model_class = Aliquot

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

  def prepare_list_context
    @context, @context_options = ::Aliquot.including_associations_for_json, { :order => 'updated_at DESC' }
  end

end
