class MultiplexedLibraryCreationPipeline < LibraryCreationPipeline
  include Pipeline::InboxGroupedBySubmission

  INBOX_PARTIAL='request_group_by_submission_inbox'
  
  def inbox_partial
    INBOX_PARTIAL
  end
end
