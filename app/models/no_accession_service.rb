# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

class NoAccessionService < AccessionService
  self.no_study_accession_needed = true

  def initialize(study)
    @study_id = study.id
  end

  def provider; :NONE end

  def submit(_user, *_accessionables)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study, scope: 'accession_service.not_required')
  end

  def submit_sample_for_user(_sample, _user)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study_for_sample, scope: 'accession_service.not_required', study_id: @study_id)
  end

  def submit_study_for_user(_study, _user)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study, scope: 'accession_service.not_required')
  end

  def submit_dac_for_user(_study, _user)
    raise AccessionService::NumberNotRequired, I18n.t(:not_applicable_study_for_dac, scope: 'accession_service.not_required')
  end
end
