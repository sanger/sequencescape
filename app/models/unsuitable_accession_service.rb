# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

class UnsuitableAccessionService < AccessionService
  self.no_study_accession_needed = true

  def initialize(studies)
    @study_ids = studies.map(&:id)
  end

  def provider
    :unsuitable
  end

  def submit(_user, *_accessionables)
    raise AccessionService::NumberNotGenerated, I18n.t(:no_suitable_study, scope: 'accession_service.unsuitable', study_ids: @study_ids.to_sentence)
  end

  def submit_sample_for_user(_sample, _user)
    raise AccessionService::NumberNotGenerated, I18n.t(:no_suitable_study, scope: 'accession_service.unsuitable', study_ids: @study_ids.to_sentence)
  end

  def submit_study_for_user(_study, _user)
    raise StandardError, 'UnsuitableAccessionService should only be used for samples. This is a problem with Sequencescape and should be reported.'
  end

  def submit_dac_for_user(_study, _user)
    raise StandardError, 'UnsuitableAccessionService should only be used for samples. This is a problem with Sequencescape and should be reported.'
  end
end
