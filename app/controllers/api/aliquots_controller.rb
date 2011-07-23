class Api::AliquotsController < Api::BaseController
  self.model_class = Aliquot

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

end
