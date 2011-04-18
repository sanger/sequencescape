samples_to_accession = []
Study.all.each do |study|
  next if ! (
    study.data_release_strategy == "managed" ||
    study.data_release_strategy == "open"
  )


  next unless study.ena_accession_required?
  next if study.samples.nil?

  study.samples.each do |sample|
    if sample.accession_could_be_generated?
      samples_to_accession << sample
    end
  end
end

current_user = User.find_by_api_key(configatron.accession_local_key)

samples_to_accession.each do |sample|
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
