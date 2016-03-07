#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetBillableInformationForRequestTypes < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =(:request_types)
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.update_all(
        'billable = TRUE', [
          '`key` IS NOT NULL AND `key` NOT IN (?)', [
            # Sample logistics
            'dna_qc',
            'genotyping',
            'cherrypick',
            'cherrypick_for_pulldown',
            'create_asset',

            # PacBio
            'pacbio_sample_prep',
            'pacbio_sequencing'
          ]
        ]
      )
    end
  end

  def self.down
    # Nothing to do as it will be dropped by the previous migration
  end
end
