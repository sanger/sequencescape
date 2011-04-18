class Search::FindAssetByBarcode < Search
  def scope(criteria)
    Asset.with_machine_barcode(criteria['barcode'])
  end
end
