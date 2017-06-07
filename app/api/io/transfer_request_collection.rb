# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Io::TransferRequestCollection < ::Core::Io::Base
  set_model_for_input(::TransferRequestCollection)
  set_json_root(:transfer_request_collection)

  set_eager_loading do |model|
    model
      .eager_load(:transfer_requests)
      .preload(target_tubes: [
        :uuid_object, :purpose, { aliquots: Io::Aliquot::PRELOADS }
      ])
  end

  define_attribute_and_json_mapping("
    user <= user
    transfer_requests <=> transfer_requests
    target_tubes => target_tubes
  ")
end
