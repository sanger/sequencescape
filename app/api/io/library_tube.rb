# Controls API V1 IO for {::LibraryTube}
class Io::LibraryTube < Io::Tube
  set_model_for_input(::LibraryTube)
  set_json_root(:library_tube)
  set_eager_loading(&:include_source_request)

  define_attribute_and_json_mapping("
                    source_request.request_metadata.read_length  => source_request.read_length
                   source_request.request_metadata.library_type  => source_request.library_type
    source_request.request_metadata.fragment_size_required_from  => source_request.fragment_size.from
      source_request.request_metadata.fragment_size_required_to  => source_request.fragment_size.to
  ")
end
