#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class ::Io::PlateCreation < ::Core::Io::Base
  set_model_for_input(::PlateCreation)
  set_json_root(:plate_creation)
  set_eager_loading { |model| model.include_parent.include_child }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
                  child  => child
  })
end
