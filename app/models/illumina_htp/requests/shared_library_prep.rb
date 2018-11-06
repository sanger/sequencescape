# frozen_string_literal: true

module IlluminaHtp::Requests
  # Used in the old-style WGS and ICS pipelines to reflect the shared portion
  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= next_requests.detect(&:target_tube).try(:target_tube)
    end

    def failed_downstream!
      retrospective_fail! if passed?
    end

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
    end
  end
end
