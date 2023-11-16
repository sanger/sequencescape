module Api
  module V2
    class AncestorResource < JSONAPI::Resource
    end
    class DescendantResource < JSONAPI::Resource; end
    class ParentResource < JSONAPI::Resource
      def self.records(options = {})
        class_name = options[:_relation_helper_options][:join_manager].resource_klass
        class_name.to_s.demodulize.sub(/Resource$/, '').constantize.all
      end
    end
    class ChildResource < JSONAPI::Resource; end
    class DownstreamAssetResource < JSONAPI::Resource; end
    class UpstreamAssetResource < JSONAPI::Resource; end

    class SourceReceptacleResource < JSONAPI::Resource; end
    #class ChildPlateResource < JSONAPI::Resource; end
    #class ChildTubeResource < JSONAPI::Resource; end
    #class DirectSubmissionResource < JSONAPI::Resource; end
    #class DirectSubmissionResource < JSONAPI::Resource; end

    class ParentsController < JSONAPI::ResourceController; end
    class ChildrenController < JSONAPI::ResourceController; end
    class DownstreamAssetsController < JSONAPI::ResourceController; end
    class UpstreamAssetsController < JSONAPI::ResourceController; end
    class SourceReceptaclesController < JSONAPI::ResourceController; end
    
  end
end
