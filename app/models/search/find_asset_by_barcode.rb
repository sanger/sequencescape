# frozen_string_literal: true
class Search::FindAssetByBarcode < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    Labware.with_barcode(criteria['barcode'])
  end
end
