# frozen_string_literal: true
class AccessionService::ENAService < AccessionService::BaseService
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

  # Most uses of this feature have been human error, so its better to hold off on releasing data than accidentally
  # releasing data
  def sample_visibility(_sample)
    AccessionService::HOLD
  end

  def study_visibility(_study)
    AccessionService::HOLD
  end

  def policy_visibility(_study)
    AccessionService::HOLD
  end

  def dac_visibility(_study)
    AccessionService::HOLD
  end

  def broker
    nil
  end

  def submit_policy_for_user(_user, _study)
    raise AccessionService::NumberNotGenerated, 'no need to submit Policy to ERA'
  end

  def submit_dac_for_user(_user, _study)
    raise AccessionService::NumberNotGenerated, 'no need to submit DAC  to ERA'
  end
end
