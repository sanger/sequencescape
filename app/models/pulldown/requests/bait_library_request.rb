# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module Pulldown::Requests
  # Include in request classes to allow the recording of a bait library
  module BaitLibraryRequest
    def self.included(base)
      base.class_eval do
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
        errors.add(:bait_library_id, 'Validation failed: Bait library is no longer available.') unless bait_library.visible?
      end
      private :bait_library_valid
    end
  end
end
