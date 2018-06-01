
class Api::PlatesController < Api::AssetsController
  self.model_class = Plate

  before_action :prepare_object, only: [:show, :children, :parents]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::Plate.including_associations_for_json
  end
end
