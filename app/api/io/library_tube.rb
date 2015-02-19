#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class Io::LibraryTube < Io::Tube
  set_model_for_input(::LibraryTube)
  set_json_root(:library_tube)
  set_eager_loading { |model| model.include_source_request }

  define_attribute_and_json_mapping(%Q{
                    source_request.request_metadata.read_length  => source_request.read_length
                   source_request.request_metadata.library_type  => source_request.library_type
    source_request.request_metadata.fragment_size_required_from  => source_request.fragment_size.from
      source_request.request_metadata.fragment_size_required_to  => source_request.fragment_size.to
  })
end
