module SampleManifestExcel
  module SpecialisedField
    class SampleEbiAccessionNumber
      include Base
      
      validate :check_equality

    private

      def check_equality
        accession_number = sample.sample_metadata.sample_ebi_accession_number
        if value.present? && accession_number.present?
          errors.add(:base, "The accession number does not match the existing accession number.")
        end
      end
    end
  end
end