# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module Pulldown::Requests
  # Uses to re-pool previously made libraries with a different bait
  # (Or the same bait, if someone just wants more material, or to adjust pooling)
  class ReIscLibraryRequest < IscLibraryRequest
    # Pre-capture pools depend on the ability to identify the library requests
    # when pooling occurs.
    # The requires us to identify the stock wells of the well we are looking at.
    # In the case of repool requests however these well are not stock wells by default.
    # Instead we add them manually.
    after_create :flag_asset_as_stock_well
    def flag_asset_as_stock_well
      asset.stock_wells << asset
    end
  end
end
