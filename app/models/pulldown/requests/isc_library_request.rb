# frozen_string_literal: true

module Pulldown::Requests
  # Indexed Sequence Capture
  # Samples are tagged, pooled to together in pre-capture pools
  # then they are subject to sequence capture, which enriches
  # specific sections of DNA. This allows separation of DNA
  # by species, or focusing on the exome (coding-regions)
  class IscLibraryRequest < LibraryCreation
    include BaitLibraryRequest
    include PreCapturePool::Poolable

    Metadata.class_eval do
      custom_attribute(:pre_capture_plex_level, default: 8, integer: true)
    end

    def update_pool_information(pool_information)
      super
      pool_information[:request_type] = request_type.key
    end
  end
end
