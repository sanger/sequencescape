class Api::LanesController < Api::AssetsController
  self.model_class = Lane

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::Lane.including_associations_for_json
    @context = ::LibraryTube.find(params[:library_tube_id]).children unless params[:library_tube_id].blank?
  end
end
