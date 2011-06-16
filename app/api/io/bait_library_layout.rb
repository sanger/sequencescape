class ::Io::BaitLibraryLayout < ::Core::Io::Base
  set_model_for_input(::BaitLibraryLayout)
  set_json_root(:bait_library_layout)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
      user <=> user
     plate <=> plate
    layout  => layout
  })
end
