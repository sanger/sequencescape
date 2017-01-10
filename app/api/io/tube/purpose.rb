# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.
require_dependency 'tube/purpose'

class Io::Tube::Purpose < Core::Io::Base
  set_model_for_input(::Tube::Purpose)
  set_json_root(:tube_purpose)

  define_attribute_and_json_mapping("
    name  <=> name
    parent_purposes <= parents
    child_purposes <= children
    target_type <= target_type
    type <= type
  ")
end
