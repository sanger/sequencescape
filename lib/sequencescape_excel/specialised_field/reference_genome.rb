# frozen_string_literal: true

module SequencescapeExcel
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
        return @reference_genome if defined?(@reference_genome)

        @reference_genome = ::ReferenceGenome.find_by(name: value)
      end

      private

      def check_reference_genome_exists
        return if reference_genome.present?

        errors.add(:base, "could not find #{value} reference genome.")
      end
    end
  end
end
