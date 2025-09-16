# frozen_string_literal: true

# Library tubes in legacy Sequencescape Pacbio pipelines
class PacBioLibraryTube < Tube
  include Api::PacBioLibraryTubeIo::Extensions

  extend Metadata

  has_metadata do
    custom_attribute(:prep_kit_barcode)
    custom_attribute(:binding_kit_barcode)
    custom_attribute(:smrt_cells_available)
    custom_attribute(:movie_length)
  end
end
