class Api::WellsController < Api::AssetsController
  self.model_class = Well

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::Well.including_associations_for_json
  end
end
