# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

class EgaAccessionService < AccessionService
  def provider
    :EGA
  end

  def accession_options
    configatron.accession.ega!.to_hash
  end

  def sample_visibility(_sample)
    Protect
  end

  def study_visibility(_study)
    Protect
  end

  def broker
    "EGA"
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

  # def submit(user, *accessionables)
    # accessionables.each(&:protect)

    # super(user, *accessionables)
  # end
end
