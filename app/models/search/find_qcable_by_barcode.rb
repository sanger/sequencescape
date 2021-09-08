# frozen_string_literal: true
class Search::FindQcableByBarcode < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    Qcable.with_barcode(criteria['barcode'])
  end
end
