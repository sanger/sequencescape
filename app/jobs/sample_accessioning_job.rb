SampleAccessioningJob = Struct.new(:accessionable) do
  def perform
    submission = Accession::Submission.new(User.find_by(api_key: configatron.accession_local_key), accessionable)
    submission.post
    submission.update_accession_number
  end

  def reschedule_at(current_time, _attempts)
    current_time + 1.day
  end

  def max_attempts
    3
  end

  def queue_name
    'sample_accessioning'
  end
end
