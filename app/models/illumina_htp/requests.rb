# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.

module IlluminaHtp::Requests
  class StdLibraryRequest < Request::LibraryCreation
    fragment_size_details(:no_default, :no_default)

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
      pool_information[:request_type] = request_type.key
    end

    delegate :role, to: :order

    validate :valid_purpose?
    def valid_purpose?
      return true if request_type.acceptable_plate_purposes.empty? ||
        request_type.acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add(:asset, "#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end
  end

  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= submission.next_requests(self).detect { |r| r.target_tube }.try(:target_tube)
    end

    def on_failed
      submission.next_requests(self).each(&:failed_upstream!)
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
