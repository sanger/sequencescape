class Api::PulldownMultiplexedLibraryTubesController < Api::AssetsController
  self.model_class = PulldownMultiplexedLibraryTube

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

  private

    def prepare_list_context
      @context = ::PulldownMultiplexedLibraryTube.including_associations_for_json
    end
end
