class Api::SampleTubesController < Api::AssetsController
  self.model_class = SampleTube

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

private

  def prepare_list_context
    @context = ::SampleTube.including_associations_for_json
    @context = ::SampleTube.with_sample_id(params[:sample_id]) unless params[:sample_id].nil?
  end
end
