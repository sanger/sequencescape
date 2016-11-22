SampleAccessioningJob = Struct.new(:sample) do
  def perform
    begin
      if sample.accession_service.present?
        if sample.accession_service.operational
          sample.validate_ena_required_fields!
          sample.accession_service.submit_sample_for_user(sample, User.find_by_api_key(configatron.accession_local_key))
        end
      end
    rescue
    end
  end

  def reschedule_at(current_time, attempts)
    current_time + 1.day
  end

  def max_attempts
    3
  end
end