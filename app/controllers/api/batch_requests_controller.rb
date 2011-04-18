class Api::BatchRequestsController < Api::BaseController
  self.model_class = BatchRequest

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context, @context_options = ::BatchRequest.including_associations_for_json, { :order => 'id DESC' }
  end
end
