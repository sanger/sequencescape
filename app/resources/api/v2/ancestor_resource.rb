module Api
  module V2
    class AncestorResource < JSONAPI::Resource; end
    class DescendantResource < JSONAPI::Resource; end
    class ParentResource < JSONAPI::Resource; end
    class ChildResource < JSONAPI::Resource; end
    class DownstreamAssetResource < JSONAPI::Resource; end
    class UpstreamAssetResource < JSONAPI::Resource; end
    #class ChildPlateResource < JSONAPI::Resource; end
    #class ChildTubeResource < JSONAPI::Resource; end
    #class DirectSubmissionResource < JSONAPI::Resource; end
    #class DirectSubmissionResource < JSONAPI::Resource; end

    class ParentsController < JSONAPI::ResourceController; end
    class ChildrenController < JSONAPI::ResourceController; end
    class DownstreamAssetsController < JSONAPI::ResourceController; end
    class UpstreamAssetsController < JSONAPI::ResourceController; end
    
  end
end
