#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.

class ::Io::ProcessMetadatumCollection < ::Core::Io::Base
  set_model_for_input(::ProcessMetadatumCollection)
  set_json_root(:process_metadatum_collection)

  define_attribute_and_json_mapping(%Q{
             metadata <=> metadata
             user <=> user
             asset <=> asset
  })

end
