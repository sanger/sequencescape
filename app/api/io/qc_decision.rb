#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class Io::QcDecision < Core::Io::Base
  set_model_for_input(::QcDecision)
  set_json_root(:qc_decision)

  define_attribute_and_json_mapping(%Q{
                user <=> user
                 lot <=> lot
           decisions <= decisions
  })
end
