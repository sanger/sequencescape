# frozen_string_literal: true


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
