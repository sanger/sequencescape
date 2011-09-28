class Api::AliquotsController < Api::BaseController
  self.model_class = Aliquot

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

  def prepare_list_context
    @context, @context_options = ::Aliquot.including_associations_for_json, { :order => 'updated_at DESC' }
  end

end
