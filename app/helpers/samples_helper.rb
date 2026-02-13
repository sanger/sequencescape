# frozen_string_literal: true

module SamplesHelper
  # Indicate to the user that saving the sample will also accession it
  # This will not happen if the study has not been accessioned
  def save_text(sample)
    if [accessioning_enabled?, sample.should_be_accessioned?, permitted_to_accession?(sample)].all?
      return 'Save and Accession'
    end

    'Save Sample'
  end

  def samples_not_accessioned(samples)
    return 'All samples accessioned' if samples.all?(&:accession_number?)

    "#{samples.count { |sample| !sample.accession_number? }} samples not accessioned"
  end
end
