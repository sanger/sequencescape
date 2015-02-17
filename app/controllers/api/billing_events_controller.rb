#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Api::BillingEventsController < Api::BaseController
  self.model_class = BillingEvent

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]

private
  def prepare_list_context
    @context, @context_options = BillingEvent.including_associations_for_json, { :order => 'id DESC' }
  end
end
