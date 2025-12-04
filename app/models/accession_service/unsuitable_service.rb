# frozen_string_literal: true
# Used for samples/studies which are neither open or managed.
class AccessionService::UnsuitableService < AccessionService::BaseService
  self.no_study_accession_needed = true

  def initialize(studies)
    @study_ids = studies.map(&:id)
  end

  def provider
    :unsuitable
  end

  def submit(_user, *_accessionables)
    raise AccessionService::NumberNotGenerated,
          I18n.t(:no_suitable_study, scope: 'accession_service.unsuitable', study_ids: @study_ids.to_sentence)
  end

  def submit_sample_for_user(_sample, _user)
    raise AccessionService::NumberNotGenerated,
          I18n.t(:no_suitable_study, scope: 'accession_service.unsuitable', study_ids: @study_ids.to_sentence)
  end

  def submit_study_for_user(_study, _user)
    raise StandardError,
          # rubocop:todo Layout/LineLength
          'UnsuitableAccessionService should only be used for samples. This is a problem with Sequencescape and should be reported.'
    # rubocop:enable Layout/LineLength
  end

  def submit_dac_for_user(_study, _user)
    raise StandardError,
          # rubocop:todo Layout/LineLength
          'UnsuitableAccessionService should only be used for samples. This is a problem with Sequencescape and should be reported.'
    # rubocop:enable Layout/LineLength
  end
end
