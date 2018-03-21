# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.

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
