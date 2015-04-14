#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class Io::Stamp < Core::Io::Base
  set_model_for_input(::Stamp)
  set_json_root(:stamp)

  define_attribute_and_json_mapping(%Q{
          tip_lot <=> tip_lot
             user <=> user
              lot <=> lot
            robot <=> robot

    stamp_details <= stamp_details
  })
end
