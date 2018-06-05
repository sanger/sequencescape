
class Api::AliquotsController < Api::BaseController
  self.model_class = Aliquot

  before_action :prepare_object, only: [:show, :update, :destroy]
  before_action :prepare_list_context, only: [:index]

  def prepare_list_context
    @context, @context_order = ::Aliquot.including_associations_for_json, { updated_at: :desc }
  end
end
