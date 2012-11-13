class ::Io::MultiplexedLibraryTube < ::Io::LibraryTube
  set_model_for_input(::MultiplexedLibraryTube)
  set_json_root(:multiplexed_library_tube)

  define_attribute_and_json_mapping('')
  # TODO: Find an efficient way to display state as it kills transfers_to_tubes for plates!
#  define_attribute_and_json_mapping(%Q{
#    state  => state
#  })
end
