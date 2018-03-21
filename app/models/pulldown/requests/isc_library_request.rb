# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module Pulldown::Requests
  # Indexed Sequences Capture
  # Samples are tagged, pooled to together in pre-capture pools
  # then they are subject to sequence capture, which enriches
  # specific sections of DNA. This allows separation of DNA
  # by species, or focusing on the exome (coding-regions)
  class IscLibraryRequest < LibraryCreation
    include BaitLibraryRequest
    include PreCapturePool::Poolable
    include Request::ApplyLibraryInfoOnPass

    Metadata.class_eval do
      custom_attribute(:pre_capture_plex_level, default: 8, integer: true)
    end

    def update_pool_information(pool_information)
      super
      pool_information[:request_type] = request_type.key
    end

    def billing_product_identifier
      bait_library = request_metadata.try(:bait_library)
      bait_library.category if bait_library.present?
    end
  end
end
