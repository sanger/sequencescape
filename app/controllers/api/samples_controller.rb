class Api::SamplesController < Api::BaseController
  self.model_class = Sample

  before_filter :prepare_object, :only => [ :show, :update, :destroy ]
  before_filter :prepare_list_context, :only => [ :index ]

  def next_sanger_sample_id
    respond_to do |format|
      format.json { render :json => SangerSampleId.create().id }
    end
  end

private

  def prepare_list_context
    @context = ::Sample.including_associations_for_json
    @context = ::Study.find(params[:study_id]).samples unless params[:study_id].blank?
  end
end
