SampleAccessioningJob = Struct.new(:sample) do
  def perform
  end

  def reschedule_at(current_time, attempts)
    current_time + 1.day
  end

  def max_attempts
    3
  end
end