class ::Io::PacBioLibraryTube < ::Io::Asset
  set_model_for_input(::PacBioLibraryTube)
  set_json_root(:pac_bio_library_tube)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
        pac_bio_library_tube_metadata.prep_kit_barcode <=> prep_kit_barcode
     pac_bio_library_tube_metadata.binding_kit_barcode <=> binding_kit_barcode
    pac_bio_library_tube_metadata.smrt_cells_available <=> smrt_cells_available
            pac_bio_library_tube_metadata.movie_length <=> movie_length
  })
end
