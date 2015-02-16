#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class ::Io::Search < ::Core::Io::Base
  set_json_root(:search)

  define_attribute_and_json_mapping(%Q{
    name  => name
  })
end
