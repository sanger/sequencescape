# frozen_string_literal: true
# Used by Gatekeeper to find the lot associated with a batch.
# Not used nowadays, as QC is no longer performed in house.
class Search::FindLotByBatchId < Search
  def scope(criteria)
    root_asset = parent_of_purpose(Batch.find_by(id: criteria['batch_id']))
    Lot.with_qc_asset(root_asset)
  end

  def parent_of_purpose(batch)
    input_labware = batch&.input_labware
    return nil if input_labware.empty?

    input_labware.first.ancestors.joins(:purpose).find_by(plate_purposes: { name: 'Tag PCR' })
  end
end
