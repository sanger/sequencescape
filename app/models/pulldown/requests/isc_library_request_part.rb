# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module Pulldown::Requests
  # ISC (Indexed sequence capture) used in split style High Throughput requests
  # The top-half of the pipeline is a SharedLibraryPrep and this ensures
  # that upstream requests get failed when the matching downstream request
  # is failed.
  class IscLibraryRequestPart < IscLibraryRequest
    include IlluminaHtp::Requests::LibraryCompletion::FailUpstream
  end
end
