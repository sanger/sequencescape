
class Api::AssetLinksController < Api::BaseController
  self.model_class = AssetLink

  before_action :prepare_object, only: [:show]
  before_action :prepare_list_context, only: [:index]

  def prepare_list_context
    @context = ::AssetLink.including_associations_for_json
  end
end
