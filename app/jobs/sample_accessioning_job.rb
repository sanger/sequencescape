SampleAccessioningJob = Struct.new(:operation) do
  def perform
    operation.post
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
