# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Io::PlatePurpose < Core::Io::Base
  set_model_for_input(::PlatePurpose)
  set_json_root(:plate_purpose)

  define_attribute_and_json_mapping("
    name <=> name
    lifespan <=> lifespan
    cherrypickable_target <=> cherrypickable_target
    can_be_considered_a_stock_plate <=> stock_plate
    parent_uuids <= parent_uuids
    child_uuids <= child_uuids
  ")
end
