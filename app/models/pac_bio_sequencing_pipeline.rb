class PacBioSequencingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  self.inbox_partial = 'pac_bio_sequencing_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  self.requires_position = false

  def post_release_batch(batch, _user)
    batch.requests.each(&:transfer_aliquots)
    Messenger.create!(target: batch, template: 'PacBioRunIO', root: 'pac_bio_run')
  end
end
