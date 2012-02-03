class SetBillableInformationForRequestTypes < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    set_table_name(:request_types)
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
