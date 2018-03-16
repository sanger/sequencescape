# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class ::Io::TubeFromTubeCreation < ::Core::Io::Base
  set_model_for_input(::TubeFromTubeCreation)
  set_json_root(:tube_from_tube_creation)

  set_eager_loading { |model| model.includes(parent: { aliquots: Io::Aliquot::PRELOADS }) }

  define_attribute_and_json_mapping("
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
  ")
end
