class MultiplexedLibraryCreationPipeline < LibraryCreationPipeline # rubocop:todo Style/Documentation
  include Pipeline::InboxGroupedBySubmission

  self.batch_worksheet = 'multiplexed_library_worksheet'
  self.inbox_partial = 'request_group_by_submission_inbox'

  # For a batch to be valid for completion in this pipeline it must have had the tags assigned to the
  # target assets of the requests.
  def validation_of_batch_for_completion(batch)
    return true unless batch.requests.any? { |r| r.target_asset.aliquots.any? { |a| a.tag.nil? } }

    batch.errors.add(:base, 'This batch appears to have not been properly tagged')
  end
end
