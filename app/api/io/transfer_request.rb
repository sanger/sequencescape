# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Io
  class TransferRequest < ::Core::Io::Base
    set_model_for_input(::TransferRequest)
    set_json_root(:request)
    set_eager_loading do |model|
      model
        .includes(asset: :uuid_object)
        .includes(target_asset: :uuid_object)
    end

    define_attribute_and_json_mapping("
      state <=> state

      submission.uuid  => submission.uuid
      submission <= submission
      asset <=  source_asset
      target_asset <=  target_asset
    ")
  end
end
