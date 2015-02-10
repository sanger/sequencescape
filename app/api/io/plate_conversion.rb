#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ::Io::PlateConversion < ::Core::Io::Base
  set_model_for_input(::PlateConversion)
  set_json_root(:plate_conversion)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 target <=> target
                purpose <=> purpose
                 parent <=  parent
  })
end
