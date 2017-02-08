SampleAccessioningJob = Struct.new(:sample) do
  def perform
    accessionable = Accession::Sample.new(Accession.configuration.tags, sample)
    if accessionable.valid?
      submission = Accession::Submission.new(User.find_by_api_key(configatron.accession_local_key), accessionable)
      submission.post
      submission.update_accession_number
    end
  end

  def reschedule_at(current_time, attempts)
    current_time + 1.day
  end

  def max_attempts
    3
  end

  def queue_name
    'sample_accessioning'
  end
end
