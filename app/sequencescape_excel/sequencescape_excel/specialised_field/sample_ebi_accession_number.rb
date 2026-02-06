# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # The accession number should only be updated if it is currently null or it is the same
    # If the accession number differs from the current one the world will come crashing down.
    class SampleEBIAccessionNumber
      include Base

      validate :check_equality

      def update(_attributes = {})
        return if value.blank?

        sample.sample_metadata.sample_ebi_accession_number ||= value if valid?
      end

      private

      def existing_accession_number
        sample&.sample_metadata&.sample_ebi_accession_number
      end

      def check_equality
        return unless value.present? && existing_accession_number.present?
        return if value == existing_accession_number

        errors.add(:base, 'The accession number does not match the existing accession number.')
      end
    end
  end
end
