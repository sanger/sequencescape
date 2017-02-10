# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015,2016 Genome Research Ltd.

class EnaAccessionService < AccessionService
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

  # Most uses of this feature have been human error, so its better to hold off on releasing data than accidentally releasing data

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
