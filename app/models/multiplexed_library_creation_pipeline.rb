#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class MultiplexedLibraryCreationPipeline < LibraryCreationPipeline
  include Pipeline::InboxGroupedBySubmission

  INBOX_PARTIAL='request_group_by_submission_inbox'

  def inbox_partial
    INBOX_PARTIAL
  end

  # For a batch to be valid for completion in this pipeline it must have had the tags assigned to the
  # target assets of the requests.
  def validation_of_batch_for_completion(batch)
    batch.errors.add(:base,'This batch appears to have not been properly tagged') if batch.requests.any? do |r|
      r.target_asset.aliquots.map(&:tag).compact.size != r.target_asset.aliquots.size
    end
  end
end
