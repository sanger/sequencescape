# frozen_string_literal: true
class AccessionService::EGAService < AccessionService::BaseService
  self.priority = 2
  self.operational = true

  def provider
    :EGA
  end

  def accession_options
    configatron.accession.ega!.to_hash
  end

  def sample_visibility(_sample)
    AccessionService::PROTECT
  end

  def study_visibility(_study)
    AccessionService::PROTECT
  end

  def broker
    'EGA'
  end

  def submit_dac_for_user(study, user)
    submit(user, Accessionable::Dac.new(study))
  end

  def submit_policy_for_user(study, user)
    policy = Accessionable::Policy.new(study)
    submit(user, policy)
  end

  def private?
    true
  end
end
