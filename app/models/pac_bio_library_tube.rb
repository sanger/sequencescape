class PacBioLibraryTube < Tube
  include Api::PacBioLibraryTubeIO::Extensions

  extend Metadata
  has_metadata do
    attribute(:prep_kit_barcode)
    attribute(:binding_kit_barcode)
    attribute(:smrt_cells_available)
    attribute(:movie_length)
  end
  
  
  def protocols_for_select
    ReferenceGenome.sorted_by_name.map { |x| [x.name, x.id]}.tap do |protocols|
      reference_genome = primary_aliquot.sample.sample_reference_genome
      protocols.unshift([reference_genome.name, reference_genome.id]) if reference_genome.present?
    end
  end
end
