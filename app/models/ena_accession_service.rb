class EnaAccessionService < AccessionService # rubocop:todo Style/Documentation
  self.priority = 1
  self.operational = true

  def provider
    :ENA
  end

  def accession_options
    configatron.accession.ena!.to_hash
  end

  def accession_login
    configatron.ena_accession_login or raise "Can't find ENA accession login in configuration file"
  end

  # rubocop:todo Layout/LineLength
  # Most uses of this feature have been human error, so its better to hold off on releasing data than accidentally releasing data
  # rubocop:enable Layout/LineLength

  def sample_visibility(_sample)
    Hold
  end

  def study_visibility(_study)
    Hold
  end

  def policy_visibility(_study)
    Hold
  end

  def dac_visibility(_study)
    Hold
  end

  def broker
    nil
  end

  def submit_policy_for_user(_user, _study)
    raise NumberNotGenerated, 'no need to submit Policy to ERA'
  end

  def submit_dac_for_user(_user, _study)
    raise NumberNotGenerated, 'no need to submit DAC  to ERA'
  end
end
