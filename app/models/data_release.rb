module DataRelease
  # TODO[xxx]: All of this probably falls into the Study::Metadata class

  def valid_data_release_properties?
    return true unless self.enforce_data_release
    return false if self.study_metadata.data_release_study_type.is_not_specified?
    return false if self.study_metadata.data_release_strategy.blank?
    return false if self.study_metadata.data_release_timing.blank?
    true
  end

  def ena_accession_required?
    return false unless self.enforce_accessioning
    return true unless valid_data_release_properties?
    return false if self.study_metadata.data_release_study_type.include_type?
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
