#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ::Io::TagGroup < ::Core::Io::Base
  set_model_for_input(::TagGroup)
  set_json_root(:tag_group)

  define_attribute_and_json_mapping(%Q{
            name  => name
    indexed_tags  => tags
  })
end
