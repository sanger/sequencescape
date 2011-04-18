class PacBioLibraryTube < Asset
  include LocationAssociation::Locatable
  
  extend Metadata
  has_metadata do
    attribute(:prep_kit_barcode)
    attribute(:binding_kit_barcode)
    attribute(:smrt_cells_available)
    attribute(:movie_length)
  end
  
  
  def protocols_for_select
    reference_genome = self.sample.sample_reference_genome
    protocols = ReferenceGenome.sorted_by_name.map { |x| [x.name, x.id]}
    if reference_genome
      return ([[reference_genome.name, reference_genome.id]] + protocols)
    end
    
    protocols
  end
end
