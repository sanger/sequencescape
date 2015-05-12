#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015 Genome Research Ltd.
class ::Io::TagLayoutTemplate < ::Core::Io::Base
  set_model_for_input(::TagLayoutTemplate)
  set_json_root(:tag_layout_template)
  set_eager_loading { |model| model.include_tags }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
                 name  => name
            tag_group  => tag_group
            direction  => direction
           walking_by  => walking_by
  })
end
