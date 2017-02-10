# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

module DataRelease
  # TODO[xxx]: All of this probably falls into the Study::Metadata class

  def valid_data_release_properties?
    return true unless enforce_data_release
    return false if study_metadata.data_release_study_type.try(:is_not_specified?)
    return false if study_metadata.data_release_strategy.try(:blank?)
    return false if study_metadata.data_release_timing.try(:blank?)
    true
  end

  def ena_accession_required?
    return false unless enforce_accessioning
    return true unless valid_data_release_properties?
    return false if study_metadata.data_release_study_type.try(:studies_excluded_for_release?)
    # TODO[xxx]: was this removed?
    return false if study_metadata.never_release?
    true
  end

  def for_array_express?
    (st = study_metadata.data_release_study_type) && st.for_array_express
  end
end
