class Search::FindSourceAssetsByDestinationAssetBarcode < Search
  def scope(criteria)
    Asset.source_assets_from_machine_barcode(criteria['barcode'])
  end
end
