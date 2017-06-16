# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class ::Io::SpecificTubeCreation < ::Core::Io::Base
  set_model_for_input(::SpecificTubeCreation)
  set_json_root(:specific_tube_creation)
  set_eager_loading { |model| model.include_parent }

  define_attribute_and_json_mapping('
     user <=> user
     parent <=> parent
     set_child_purposes <=  child_purposes
     tube_attributes <= tube_attributes
  ')
end
