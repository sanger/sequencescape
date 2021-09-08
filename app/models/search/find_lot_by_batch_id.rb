# frozen_string_literal: true
class Search::FindLotByBatchId < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    root_asset = Batch.find_by(id: criteria['batch_id']).try(:parent_of_purpose, 'Tag PCR')
    Lot.with_qc_asset(root_asset)
  end
end
