class EraAccessionService < AccessionService
  def accession_from_ebi(submission_filename, submission_file_handle, type_filename, type_file_handle, type)
    generate_accession_from_ebi(submission_filename, submission_file_handle, type_filename, type_file_handle, type, configatron.era_accession_login)
  end

  def accession_login
    configatron.era_accession_login or raise RuntimeError,  "Can't find ERA  accession login in configuration file"
  end
  # Most uses of this feature have been human error, so its better to hold off on releasing data than accidentally releasing data
  def sample_visibility(sample)
    #sample_hold = sample.sample_sra_hold
    #sample_hold.blank? ? 'hold' : sample_hold
    Hold
  end

  def study_visibility(study)
    #study_hold = study.study_sra_hold
    #study_hold.blank? ? 'hold' : study_hold
    Hold
  end

  def policy_visibility(study)
    Hold
  end

  def dac_visibility(study)
    Hold
  end

  def broker
    nil
  end

  def submit_policy_for_user(user, study)
    raise NumberNotGenerated, "no need to submit Policy to ERA"
  end

  def submit_dac_for_user(user, study)
    raise NumberNotGenerated, "no need to submit DAC  to ERA"
  end
end
