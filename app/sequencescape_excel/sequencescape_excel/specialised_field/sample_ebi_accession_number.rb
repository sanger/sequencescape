# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # The accession number should only be updated if it is currently null or it is the same
    # If the accession number differs from the current one the world will come crashing down.
    class SampleEbiAccessionNumber
      include Base

      validate :check_equality

      private

      def check_equality
        accession_number = sample.sample_metadata.sample_ebi_accession_number
        return unless value.present? && accession_number.present?
        errors.add(:base, 'The accession number does not match the existing accession number.')
      end
    end
  end
end
