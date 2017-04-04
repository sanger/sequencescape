# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class MultiplexedLibraryCreationPipeline < LibraryCreationPipeline
  include Pipeline::InboxGroupedBySubmission

  self.batch_worksheet = 'multiplexed_library_worksheet'
  self.inbox_partial = 'request_group_by_submission_inbox'

  # For a batch to be valid for completion in this pipeline it must have had the tags assigned to the
  # target assets of the requests.
  def validation_of_batch_for_completion(batch)
    return true unless batch.requests.any? do |r|
      r.target_asset.aliquots.any? { |a| a.tag.nil? }
    end
    batch.errors.add(:base, 'This batch appears to have not been properly tagged')
    # raise ActiveRecord::RecordInvalid, batch
  end
end
