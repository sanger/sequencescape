# frozen_string_literal: true
class Search::FindSourceAssetsByDestinationAssetBarcode < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    Labware.source_assets_from_machine_barcode(criteria['barcode'])
  end
end
