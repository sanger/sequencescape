# Triggers the building of the submission
SubmissionBuilderJob = Struct.new(:submission_id) do
  def perform
    Submission.find(submission_id).build_batch
  end
end
