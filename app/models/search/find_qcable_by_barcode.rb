# frozen_string_literal: true
class Search::FindQcableByBarcode < Search
  def scope(criteria)
    Qcable.with_barcode(criteria['barcode'])
  end
end
