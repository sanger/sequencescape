class PacBioSequencingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  INBOX_PARTIAL               = 'pac_bio_sequencing_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def inbox_partial
    INBOX_PARTIAL
  end

  # PacBio pipelines do not require their batches to record the position of their requests.
  def requires_position?
    false
  end
end
