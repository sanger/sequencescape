#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
module DataRelease
  # TODO[xxx]: All of this probably falls into the Study::Metadata class

  def valid_data_release_properties?
    return true unless self.enforce_data_release
    return false if self.study_metadata.data_release_study_type.try(:is_not_specified?)
    return false if self.study_metadata.data_release_strategy.try(:blank?)
    return false if self.study_metadata.data_release_timing.try(:blank?)
    true
  end

  def ena_accession_required?
    return false unless self.enforce_accessioning
    return true unless valid_data_release_properties?
    return false if self.study_metadata.data_release_study_type.try(:studies_excluded_for_release?)
    # TODO[xxx]: was this removed?
    return false if [ 'never', 'delayed' ].include?(self.study_metadata.data_release_timing)
    true
  end

  def all_samples_have_accession_numbers?
    samples.all?(&:accession_number?)
  end

  def for_array_express?
    (st=self.study_metadata.data_release_study_type) && st.for_array_express
  end

end
