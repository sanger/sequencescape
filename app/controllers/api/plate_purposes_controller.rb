class Api::PlatePurposesController < Api::BaseController
  self.model_class = PlatePurpose

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]
end
