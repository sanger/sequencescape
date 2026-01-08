# frozen_string_literal: true

module SamplesHelper
  # Indicate to the user that saving the sample will also accession it
  # This will not happen if the study has not been accessioned
  def save_text(sample)
    return 'Save and Accession' if sample.ena_study.accession_number?

    'Save Sample'
  end
end
