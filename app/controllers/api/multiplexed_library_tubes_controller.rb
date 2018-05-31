
class Api::MultiplexedLibraryTubesController < Api::AssetsController
  self.model_class = MultiplexedLibraryTube

  before_action :prepare_object, only: [:show, :children, :parents]
  before_action :prepare_list_context, only: [:index]

  private

  def prepare_list_context
    @context = ::MultiplexedLibraryTube.including_associations_for_json
  end
end
