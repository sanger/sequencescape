class Api::MultiplexedLibraryTubesController < Api::AssetsController
  self.model_class = MultiplexedLibraryTube

  before_filter :prepare_object, :only => [ :show, :children, :parents ]
  before_filter :prepare_list_context, :only => [ :index ]

  private

    def prepare_list_context
      @context = ::MultiplexedLibraryTube.including_associations_for_json
    end
end
