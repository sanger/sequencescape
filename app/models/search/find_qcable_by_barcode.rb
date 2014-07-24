class Search::FindQcableByBarcode < Search
  def scope(criteria)
    Qcable.with_machine_barcode(criteria['barcode'])
  end
end
