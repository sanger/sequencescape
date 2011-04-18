class Api::ProjectsController < Api::BaseController
  self.model_class = Project

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::Project
    @context = ::Study.find(params[:study_id]).projects unless params[:study_id].blank?
  end
end

