# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

class ::Io::WorkCompletion < ::Core::Io::Base
  set_model_for_input(::WorkCompletion)
  set_json_root(:work_completion)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
    user <= user
    target <= target
    submissions <= submissions
  ")
end
