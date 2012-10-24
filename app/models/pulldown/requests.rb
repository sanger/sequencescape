module Pulldown::Requests
  module BaitLibraryRequest
    def self.included(base)
      base.class_eval do
        const_set(:DEFAULT_LIBRARY_TYPE, 'Agilent Pulldown')
        const_set(:LIBRARY_TYPES, [ 'Agilent Pulldown' ])

        fragment_size_details(100, 400)
      end
      base::Metadata.class_eval do
        include Pulldown::Requests::BaitLibraryRequest::BaitMetadata
      end
    end

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:bait_library] = request_metadata.bait_library
    end

    module BaitMetadata
      def self.included(base)
        base.class_eval do
          include BaitLibrary::Associations
          association(:bait_library, :name, :scope => :visible)
          validates_presence_of :bait_library
          validate :bait_library_valid
        end
      end

      def bait_library_valid
        errors.add(:bait_library_id, "Validation failed: Bait library is no longer available.") unless bait_library.visible?
      end
      private :bait_library_valid
    end
  end

  class LibraryCreation < Request::LibraryCreation

  end

  class WgsLibraryRequest < LibraryCreation
    DEFAULT_LIBRARY_TYPE = 'Standard'
    LIBRARY_TYPES        = [ DEFAULT_LIBRARY_TYPE ]

    fragment_size_details(300, 500)
  end

  class ScLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end

  class IscLibraryRequest < LibraryCreation
    include BaitLibraryRequest
  end
end
