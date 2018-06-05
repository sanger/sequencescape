
class Api::PulldownMultiplexedLibraryTubesController < Api::AssetsController
  self.model_class = PulldownMultiplexedLibraryTube

  before_action :prepare_object, only: [:show, :children, :parents]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::PulldownMultiplexedLibraryTube.including_associations_for_json
  end
end
