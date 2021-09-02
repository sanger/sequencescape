# frozen_string_literal: true
class PacBioLibraryTube < Tube # rubocop:todo Style/Documentation
  include Api::PacBioLibraryTubeIO::Extensions

  extend Metadata
  has_metadata do
    custom_attribute(:prep_kit_barcode)
    custom_attribute(:binding_kit_barcode)
    custom_attribute(:smrt_cells_available)
    custom_attribute(:movie_length)
  end

  def protocols_for_select
    ReferenceGenome
      .sorted_by_name
      .map { |x| [x.name, x.id] }
      .tap do |protocols|
        reference_genome = primary_aliquot.sample.sample_reference_genome
        protocols.unshift([reference_genome.name, reference_genome.id]) if reference_genome.present?
      end
  end
end
