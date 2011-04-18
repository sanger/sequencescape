class Api::StudiesController < Api::BaseController
  self.model_class = ::Study

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::Study.including_associations_for_json
    @context = ::Project.find(params[:project_id]).studies unless params[:project_id].blank?
  end
end
