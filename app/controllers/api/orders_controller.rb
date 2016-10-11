# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class Api::OrdersController < Api::BaseController
  self.model_class = Order

  before_action :prepare_object, only: [:show]
  before_action :prepare_list_context, only: [:index]

private

  def prepare_list_context
    case
    when params[:submission_id].present?
      @context = ::Submission.find(params[:submission_id]).orders
    else
      @context = ::Order.including_associations_for_json
    end
  end
end
