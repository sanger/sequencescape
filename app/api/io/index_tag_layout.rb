#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ::Io::IndexTagLayout < ::Core::Io::Base
  set_model_for_input(::IndexTagLayout)
  set_json_root(:index_tag_layout)
  set_eager_loading { |model| model.include_plate.include_tag }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                  plate <=> plate

               tag.name  => tag.name
             tag.map_id  => tag.identifier
              tag.oligo  => tag.oligo
     tag.tag_group.name  => tag.group
  })
end
