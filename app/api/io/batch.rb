#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class ::Io::Batch < ::Core::Io::Base
  set_model_for_input(::Batch)
  set_json_root(:batch)
  set_eager_loading { |model| model.include_user.include_requests.include_pipeline }

  define_attribute_and_json_mapping(%Q{
               state  => state
    production_state  => production_state
            qc_state  => qc_state
             barcode  => barcode
          user.login  => user.login

            requests <=> requests
  })
end
