class Io::LibraryTube < Io::Asset
  set_model_for_input(::LibraryTube)
  set_json_root(:library_tube)
  set_eager_loading { |model| model.include_tag.include_sample.include_source_request.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(%Q{
                                                         closed  => closed
                                                  concentration  => concentration
                                                         volume  => volume
                                                scanned_in_date  => scanned_in_date
                                   
                                                    sample.name  => sample.name

                    source_request.request_metadata.read_length  => source_request.read_length
                   source_request.request_metadata.library_type  => source_request.library_type
    source_request.request_metadata.fragment_size_required_from  => source_request.fragment_size.from
      source_request.request_metadata.fragment_size_required_to  => source_request.fragment_size.to

                                                   get_tag.uuid  => tag.uuid
                                                  get_tag.oligo  => tag.expected_sequence
                                         get_tag.tag_group.uuid  => tag.group.uuid
                                         get_tag.tag_group.name  => tag.group.name
  })
end
