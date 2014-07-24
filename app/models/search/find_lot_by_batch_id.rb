class Search::FindLotByBatchId < Search
  def scope(criteria)
    root_asset =  Batch.find_by_id(criteria['batch_id']).try(:parent_of_purpose,'Tag PCR')
    Lot.with_qc_asset(root_asset)
  end
end
