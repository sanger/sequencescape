#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
class Io::Asset < Core::Io::Base
  set_model_for_input(::Asset)
  set_json_root(:asset)
  set_eager_loading { |model| model.include_barcode_prefix }

  define_attribute_and_json_mapping(%Q{
                         name  => name
                     qc_state  => qc_state
  })
end
