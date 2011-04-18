class Api::AssetAuditsController < Api::BaseController
  self.model_class = AssetAudit

  before_filter :prepare_object, :only => [ :show ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context, @context_options = ::AssetAudit.including_associations_for_json, { :order => 'id DESC' }
  end
end
