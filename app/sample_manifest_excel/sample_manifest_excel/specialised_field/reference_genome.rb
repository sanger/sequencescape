module SampleManifestExcel
  module SpecialisedField
    ##
    # The reference genome is a value which must already exist.
    # Reference genome is stored as object on sample_metadata
    class ReferenceGenome
      include Base

      validate :check_reference_genome_exists, if: :value_present?

      attr_writer :reference_genome

      def update(_attributes = {})
        sample.sample_metadata.reference_genome = reference_genome if valid?
      end

      def reference_genome
        @reference_genome ||= ::ReferenceGenome.find_by(name: value)
      end

      private

      def check_reference_genome_exists
        errors.add(:base, "could not find #{value} reference genome.") if reference_genome.blank?
      end
    end
  end
end
