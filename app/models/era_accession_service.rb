# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

class EraAccessionService < AccessionService
  def provider
    :ERA
  end

  def accession_options
    configatron.accession.ena!.to_hash
  end

  # Most uses of this feature have been human error, so its better to hold off on releasing data than accidentally releasing data
  def sample_visibility(sample)
    # sample_hold = sample.sample_sra_hold
    # sample_hold.blank? ? 'hold' : sample_hold
    Hold
  end

  def study_visibility(study)
    # study_hold = study.study_sra_hold
    # study_hold.blank? ? 'hold' : study_hold
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
