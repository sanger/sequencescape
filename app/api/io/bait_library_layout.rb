#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ::Io::BaitLibraryLayout < ::Core::Io::Base
  set_model_for_input(::BaitLibraryLayout)
  set_json_root(:bait_library_layout)
  set_eager_loading { |model| model.include_plate }

  define_attribute_and_json_mapping(%Q{
           user <=> user
          plate <=> plate
    well_layout  => layout
  })
end
