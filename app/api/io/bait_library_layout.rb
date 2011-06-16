class ::Io::BaitLibraryLayout < ::Core::Io::Base
  set_model_for_input(::BaitLibraryLayout)
  set_json_root(:bait_library_layout)

  define_attribute_and_json_mapping(%Q{
           user <=> user
          plate <=> plate
    well_layout  => layout
  })
end
