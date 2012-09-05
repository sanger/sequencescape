class Io::LibraryCreationRequest < ::Io::Request
  set_model_for_input(::LibraryCreationRequest)
  set_json_root(:library_creation_request)

  define_attribute_and_json_mapping(%Q{
    request_metadata.library_type  => library_type
  })
end
