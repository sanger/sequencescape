
class Api::PlatePurposesController < Api::BaseController
  self.model_class = PlatePurpose

  before_action :prepare_object, only: [:show]
  before_action :prepare_list_context, only: [:index]
end
