#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ::Io::TransferTemplate < ::Core::Io::Base
  set_model_for_input(::TransferTemplate)
  set_json_root(:transfer_template)

  define_attribute_and_json_mapping(%Q{
                   name  => name
              transfers  => transfers
  })
end
