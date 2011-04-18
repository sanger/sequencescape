class Api::AssetLinksController < Api::BaseController
  self.model_class = AssetLink

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]

  def prepare_list_context
    @context, @context_options = ::AssetLink.including_associations_for_json, { :order => 'id DESC' }
  end
end
