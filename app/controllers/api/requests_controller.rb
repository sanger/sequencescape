class Api::RequestsController < Api::BaseController
  self.model_class = Request

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    if not params[:sample_tube_id].blank?
      @context = ::SampleTube.find(params[:sample_tube_id]).requests
    elsif not params[:library_tube_id].blank?
      @context = ::LibraryTube.find(params[:library_tube_id]).requests
    else
      @context = Request.including_associations_for_json
    end
  end
end
