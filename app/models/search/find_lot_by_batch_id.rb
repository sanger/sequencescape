# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class Search::FindLotByBatchId < Search
  def scope(criteria)
    root_asset = Batch.find_by(id: criteria['batch_id']).try(:parent_of_purpose, 'Tag PCR')
    Lot.with_qc_asset(root_asset)
  end
end
