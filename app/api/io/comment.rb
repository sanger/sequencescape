#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class Io::Comment < ::Core::Io::Base
  set_model_for_input(::Comment)
  set_json_root(:comment)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping(%Q{
                                           user  <=  user
                                          title  <=> title
                                    description  <=> description
  })
end
