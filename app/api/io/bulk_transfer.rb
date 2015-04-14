#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class ::Io::BulkTransfer < ::Core::Io::Base
  set_model_for_input(::BulkTransfer)
  set_json_root(:bulk_transfer)

  define_attribute_and_json_mapping(%Q{
           user <=> user
well_transfers  <=  well_transfers
  })
end
