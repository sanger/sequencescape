current_user = User.find_by_api_key(configatron.accession_local_key) or raise StandardError, "Cannot find accessioning user"
Study.find_each(:include => { :study_metadata => :data_release_study_type }) do |study|
  next if not (study.data_release_strategy == "managed" or study.data_release_strategy == "open")
  #next if study.data_release_strategy != "managed" and study.data_release_strategy != "open"
  next unless study.ena_accession_required?

  study.samples.find_each(:include => [ :sample_metadata, { :studies => :study_metadata } ]) do |sample|
    next unless sample.accession_could_be_generated?

    # Get new ebi accesion number.
    begin
      sample.validate_ena_required_fields!
      sample.accession_service.submit_sample_for_user(sample, current_user)
    rescue ActiveRecord::RecordInvalid => exception
      #warn "Please fill in the required fields for sample: #{sample.name}"
    rescue AccessionService::NumberNotRequired => exception
      #warn "An accession number is not required for this study.  Study name: #{sample.study.name}"
    rescue AccessionService::NumberNotGenerated => exception
      warn 'No accession number was generated'
    rescue AccessionService::AccessionServiceError => exception
      warn exception.message
    end
  end
end
