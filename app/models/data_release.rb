# frozen_string_literal: true
module DataRelease # rubocop:todo Style/Documentation
  # TODO[xxx]: All of this probably falls into the Study::Metadata class

  def valid_data_release_properties?
    return true unless enforce_data_release
    return false if study_metadata.data_release_strategy.try(:blank?)
    return false if study_metadata.data_release_timing.try(:blank?)

    true
  end

  def accession_required?
    return false unless enforce_accessioning
    return true unless valid_data_release_properties?

    # TODO[xxx]: was this removed?
    return false if study_metadata.never_release?

    true
  end

  def for_array_express?
    (st = study_metadata.data_release_study_type) && st.for_array_express
  end
end
