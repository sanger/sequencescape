#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2014 Genome Research Ltd.
class ::Io::TagLayout < ::Core::Io::Base
  set_model_for_input(::TagLayout)
  set_json_root(:tag_layout)
  set_eager_loading { |model| model.include_plate.include_tag_group }

  define_attribute_and_json_mapping(%Q{
             user <=> user
            plate <=> plate
    substitutions <=> substitutions
        tag_group <=> tag_group
        direction <=> direction
       walking_by <=> walking_by
      initial_tag <=> initial_tag
  })
end
