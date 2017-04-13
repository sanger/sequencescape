# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

class IlluminaC::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def created_with_request_options(tube)
    library_request(tube).try(:request_options_for_creation) || {}
  end

  def stock_plate(tube)
    lt = library_request(tube)
    return lt.asset.plate if lt.present?
    nil
  end

  def library_request(tube)
    tube.requests_as_target.where_is_a?(IlluminaC::Requests::LibraryRequest).first ||
      tube.requests_as_target.where_is_a?(Request::Multiplexing).first.asset
          .requests_as_target.where_is_a?(IlluminaC::Requests::LibraryRequest).first
  end

  def request_state(request, state)
    mappings = { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }
    request.is_a?(TransferRequest) || request.is_a?(Request::Multiplexing) ? state : mappings[state]
  end
  private :request_state
end
