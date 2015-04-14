#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Io::DilutionPlatePurpose < Io::PlatePurpose
  set_model_for_input(::DilutionPlatePurpose)
  set_json_root(:dilution_plate_purpose)

  define_attribute_and_json_mapping(%Q{

  })
end
