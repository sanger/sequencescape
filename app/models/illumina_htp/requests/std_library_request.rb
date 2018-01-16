# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.

module IlluminaHtp::Requests
  # The basic request for limber library requests
  # Also used as the base class of some of the older WGS requests
  class StdLibraryRequest < Request::LibraryCreation
    include Request::ApplyLibraryInfoOnPass

    fragment_size_details(:no_default, :no_default)

    const_get(:Metadata).class_eval do
      custom_attribute(:pcr_cycles, integer: true, minimum: 0, validator: true)
    end

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:pcr_cycles] = request_metadata.pcr_cycles
      pool_information[:request_type] = request_type.key
      pool_information[:for_multiplexing] = request_type.for_multiplexing?
    end

    delegate :role, to: :order
    delegate :acceptable_plate_purposes, to: :request_type

    validate :valid_purpose?, if: :asset_id_changed?
    def valid_purpose?
      return true if acceptable_plate_purposes.empty? ||
                     acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add(:asset, "#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end

    def on_failed
      submission.next_requests(self).each(&:failed_upstream!)
    end
  end
end
