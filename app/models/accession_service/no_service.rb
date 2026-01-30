# frozen_string_literal: true
class AccessionService::NoService < AccessionService::BaseService
  self.no_study_accession_needed = true

  def initialize(study)
    @study_id = study.id
  end

  def provider
    :NONE
  end

  def submit(_user, *_accessionables)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study, scope: 'accession_service.not_required')
  end

  def submit_study_for_user(_study, _user)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study, scope: 'accession_service.not_required')
  end

  def submit_dac_for_user(_study, _user)
    raise AccessionService::NumberNotRequired,
          I18n.t(:not_applicable_study_for_dac, scope: 'accession_service.not_required')
  end

  def submit_policy_for_user(_user, _study)
    raise AccessionService::NumberNotRequired,
          I18n.t(:not_applicable_study_for_dac, scope: 'accession_service.not_required')
  end
end
