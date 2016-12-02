# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class Api::AliquotsController < Api::BaseController
  self.model_class = Aliquot

  before_action :prepare_object, only: [:show, :update, :destroy]
  before_action :prepare_list_context, only: [:index]

  def prepare_list_context
    @context, @context_order = ::Aliquot.including_associations_for_json, { updated_at: :desc }
  end

end
