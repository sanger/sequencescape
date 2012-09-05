class  EgaAccessionService < AccessionService
  def accession_from_ebi(submission_filename, submission_file_handle, type_filename, type_file_handle, type)
    generate_accession_from_ebi(submission_filename, submission_file_handle, type_filename, type_file_handle, type, configatron.ega_accession_login)
  end

  def accession_login
    configatron.ega_accession_login or raise RuntimeError,  "Can't find EGA accession login in configuration file"
  end

  def sample_visibility(sample)
    Protect
  end

  def study_visibility(study)
    Protect
  end

  def broker
    "EGA"
  end

  def submit_dac_for_user(study, user)
    submit(user,  Accessionable::Dac.new(study))
  end

  def submit_policy_for_user(study, user)
    policy =  Accessionable::Policy.new(study)
    submit(user, policy)
  end

  def private?
    true
  end

  #def submit(user, *accessionables)
    #accessionables.each(&:protect)

    #super(user, *accessionables)
  #end
end
