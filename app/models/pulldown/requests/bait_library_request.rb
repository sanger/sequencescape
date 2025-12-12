# frozen_string_literal: true

module Pulldown::Requests
  # Include in request classes to allow the recording of a bait library
  module BaitLibraryRequest
    def self.included(base)
      base.class_eval { fragment_size_details(100, 400) }
      base::Metadata.class_eval { include Pulldown::Requests::BaitLibraryRequest::BaitMetadata }
    end

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:bait_library] = request_metadata.bait_library
    end

    # Extends the associated metadata class for bait library support
    # Do not include directly, include Pulldown::Requests::BaitLibraryRequest
    # in the parent request class
    module BaitMetadata
      def self.included(base)
        base.class_eval do
          include BaitLibrary::Associations

          association(:bait_library, :name, scope: :visible)
          validates :bait_library, presence: true
          validate :bait_library_valid
        end
      end

      def bait_library_valid
        unless bait_library.visible?
          errors.add(:bait_library_id, 'Validation failed: Bait library is no longer available.')
        end
      end
      private :bait_library_valid
    end
  end
end
