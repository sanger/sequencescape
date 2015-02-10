#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013 Genome Research Ltd.
class IlluminaB::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end

  def request_state(request,state)
    mappings = {'cancelled' =>'cancelled','failed' => 'failed','passed' => 'passed'}
    request.is_a?(TransferRequest) ? state : mappings[state]
  end
  private :request_state
end
