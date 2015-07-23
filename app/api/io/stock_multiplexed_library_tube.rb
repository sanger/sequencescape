#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class Io::StockMultiplexedLibraryTube < Io::Tube
  set_model_for_input(::StockMultiplexedLibraryTube)
  set_json_root(:tube)

  define_attribute_and_json_mapping(%Q{
                    sibling_tubes => sibling_tubes
  })
end
