
class Api::RequestsController < Api::BaseController
  self.model_class = Request

  before_action :prepare_object, only: [:show, :update, :destroy]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = if not params[:sample_tube_id].blank?
                 ::SampleTube.find(params[:sample_tube_id]).requests
               elsif not params[:library_tube_id].blank?
                 ::LibraryTube.find(params[:library_tube_id]).requests
               else
                 Request.including_associations_for_json
               end
  end
end
