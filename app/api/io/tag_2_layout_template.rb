#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ::Io::Tag2LayoutTemplate < ::Core::Io::Base
  set_model_for_input(::Tag2LayoutTemplate)
  set_json_root(:tag_2_layout_template)
  set_eager_loading { |model| model.include_tag }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
                 name  => name

              tag.name  => tag.name
            tag.map_id  => tag.identifier
             tag.oligo  => tag.oligo
    tag.tag_group.name  => tag.group
  })
end
