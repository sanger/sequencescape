class Io::SequencingRequest < ::Io::Request
  set_model_for_input(::SequencingRequest)
  set_json_root(:sequencing_request)

  define_attribute_and_json_mapping(%Q{
    request_metadata.read_length  => read_length
  })
end
