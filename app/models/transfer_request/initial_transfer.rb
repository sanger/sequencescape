#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015,2016 Genome Research Ltd.
class TransferRequest::InitialTransfer < TransferRequest
  module Behaviour
    def perform_transfer_of_contents
      target_asset.aliquots << asset.aliquots.map do |a|
        aliquot = a.dup
        aliquot.study_id = outer_request.initial_study_id
        aliquot.project_id = outer_request.initial_project_id
        aliquot
      end unless asset.failed? or asset.cancelled?
    end
    private :perform_transfer_of_contents

    def outer_request
      asset.requests.detect{|r| r.library_creation? && r.submission_id == self.submission_id}
    end
  end

  include Behaviour
end
