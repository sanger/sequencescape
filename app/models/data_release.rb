# frozen_string_literal: true
module DataRelease # rubocop:todo Style/Documentation
  # TODO[xxx]: All of this probably falls into the Study::Metadata class

  def valid_data_release_properties?
    # If the data is expected to be released, then certain fields must be filled out.
    if enforce_data_release
      return false if study_metadata.data_release_strategy.try(:blank?)
      return false if study_metadata.data_release_timing.try(:blank?)
    end

    true
  end

  def accession_required?
    return false if do_not_enforce_accessioning

    # If the data release fields are filled out correctly, and set to 'never release',
    # then accessioning is not required.
    return false if valid_data_release_properties? && study_metadata.never_release?

    # It is required unless specified otherwise,
    # to make sure the data is ready for release to the ENA or EGA.
    true
  end

  def for_array_express?
    (st = study_metadata.data_release_study_type) && st.for_array_express
  end

  # For readability.
  # Makes sense this way round, as the flag is on by default,
  # and must be actively unchecked in the case where accessioning should not be enforced
  def do_not_enforce_accessioning
    !enforce_accessioning
  end
end
