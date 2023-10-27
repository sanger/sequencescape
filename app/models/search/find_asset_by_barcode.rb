# frozen_string_literal: true
class Search::FindAssetByBarcode < Search
  def scope(criteria)
    Labware.with_barcode(criteria['barcode'])
  end
end
