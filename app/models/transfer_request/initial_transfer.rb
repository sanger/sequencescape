# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015,2016 Genome Research Ltd.

# In addition to performing standard transfer, also
# ensures that the correct study and project are set on
# subsequent aliquots, according to the library creation request.
# Ensures that plates picked under a different study get assigned to
# the correct study/project when work starts.
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

    # Requests are already loaded when this is used, hence filtering in Ruby rather than using scopes.
    def outer_request
      asset.requests.detect { |r| r.customer_request? && r.submission_id == submission_id }
    end
  end

  # This is not included in the behaviour module to avoid affecting
  # pacbio unnecessarily. THis is triggered by the state machine.
  def on_started
    outer_request.start! if outer_request.pending?
  end

  include Behaviour
end
