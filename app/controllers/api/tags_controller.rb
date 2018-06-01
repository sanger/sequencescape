
class Api::TagsController < Api::BaseController
  self.model_class = Tag

  before_action :prepare_object, only: [:show]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::Tag.including_associations_for_json
  end
end
