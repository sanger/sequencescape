class PacBioSequencingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  INBOX_PARTIAL               = 'pac_bio_sequencing_inbox'
  ALWAYS_SHOW_RELEASE_ACTIONS = true
  
  def inbox_partial
    INBOX_PARTIAL
  end
end
