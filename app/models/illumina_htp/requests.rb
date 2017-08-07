# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.

module IlluminaHtp::Requests
  class StdLibraryRequest < Request::LibraryCreation
    fragment_size_details(:no_default, :no_default)

    const_get(:Metadata).class_eval do
      attribute(:pcr_cycles, integer: true, minimum: 0, validator: true)
    end

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
      pool_information[:request_type] = request_type.key
      pool_information[:pcr_cycles] = request_metadata.pcr_cycles
    end

    delegate :role, to: :order

    validate :valid_purpose?
    def valid_purpose?
      return true if request_type.acceptable_plate_purposes.empty? ||
                     request_type.acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add(:asset, "#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end

    def on_failed
      submission.next_requests(self).each(&:failed_upstream!)
    end

    def on_passed
      super
      apply_library_information!
    end

    #
    # Applies the library information to aliquots of
    # the target asset. Library id is used for downstream
    # tracking, and primarily acts as a unique identifier.
    # Note: Automatically saves the aliquots.
    #
    # @return [IlluminaHtp::Requests] Returns itself
    #
    def apply_library_information!
      target_asset.aliquots.each do |aliquot|
        aliquot.library      ||= target_asset
        aliquot.library_type ||= library_type
        aliquot.insert_size  ||= insert_size
        aliquot.save!
      end
      self
    end
  end

  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= submission.next_requests(self).detect { |r| r.target_tube }.try(:target_tube)
    end

    def failed_downstream!
      retrospective_fail! if passed?
    end
  end

  class LibraryCompletion < StdLibraryRequest
    module FailUpstream
      def on_failed
        asset.requests_as_target.each(&:failed_downstream!)
      end
    end
    include FailUpstream
  end
end
