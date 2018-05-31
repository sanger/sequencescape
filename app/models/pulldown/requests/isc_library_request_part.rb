# frozen_string_literal: true


module Pulldown::Requests
  # ISC (Indexed sequence capture) used in split style High Throughput requests
  # The top-half of the pipeline is a SharedLibraryPrep and this ensures
  # that upstream requests get failed when the matching downstream request
  # is failed.
  class IscLibraryRequestPart < IscLibraryRequest
    include IlluminaHtp::Requests::LibraryCompletion::FailUpstream
  end
end
