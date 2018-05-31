# frozen_string_literal: true


module IlluminaHtp::Requests
  # A Library completion request is the second part of a two stage
  # library creation process. Used primarily in the old IlluminaB
  # WGS pipelines
  class LibraryCompletion < StdLibraryRequest
    # When included in a request it fails the upstream request automatically
    # when this request is failed.
    module FailUpstream
      def on_failed
        asset.requests_as_target.each(&:failed_downstream!)
      end
    end
    include FailUpstream
  end
end
