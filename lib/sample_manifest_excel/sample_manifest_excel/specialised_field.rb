module SampleManifestExcel
  ##
  # A field which either requires specific validation or needs to be updated.
  module SpecialisedField
    require_relative 'specialised_field/base'
    require_relative 'specialised_field/sanger_sample_id_value'
    require_relative 'specialised_field/value_required'
    require_relative 'specialised_field/value_to_integer'
    require_relative 'specialised_field/insert_size_from'
    require_relative 'specialised_field/insert_size_to'
    require_relative 'specialised_field/library_type'
    require_relative 'specialised_field/sample_ebi_accession_number'
    require_relative 'specialised_field/sanger_plate_id'
    require_relative 'specialised_field/sanger_sample_id'
    require_relative 'specialised_field/sanger_tube_id'
    require_relative 'specialised_field/tag2_oligo'
    require_relative 'specialised_field/tag_oligo'
    require_relative 'specialised_field/well'
  end
end
