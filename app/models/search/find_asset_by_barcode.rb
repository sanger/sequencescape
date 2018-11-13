class Search::FindAssetByBarcode < Search
  def scope(criteria)
    Asset.with_barcode(criteria['barcode'])
  end
end
