#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Io::SequencingRequest < ::Io::Request
  set_model_for_input(::SequencingRequest)
  set_json_root(:sequencing_request)

  define_attribute_and_json_mapping(%Q{
    request_metadata.read_length  => read_length
  })
end
