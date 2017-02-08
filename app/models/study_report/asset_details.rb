# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module StudyReport::AssetDetails
  def qc_report
    qc_data = {
      supplier_volume: 0
    }

    sample = primary_aliquot.try(:sample)
    if sample.present?
      supplier_sample_name = if sample.empty_supplier_sample_name
        'Blank'
                             else
        sample.sample_metadata.supplier_name || sample.sanger_sample_id || sample.name
                             end

      qc_data.merge!(supplier: sample.sample_manifest.try(:supplier).try(:name),
                     sample_name: supplier_sample_name,
                     sanger_sample_id: sample.sanger_sample_id,
                     control: sample.control,
                     status: (sample.updated_by_manifest ? 'Updated by manifest' : 'Awaiting manifest'),

                     supplier_gender: sample.sample_metadata.gender,
                     cohort: sample.sample_metadata.cohort,
                     country_of_origin: sample.sample_metadata.country_of_origin,
                     geographical_region: sample.sample_metadata.geographical_region,
                     ethnicity: sample.sample_metadata.ethnicity,
                     dna_source: sample.sample_metadata.dna_source,
                     is_resubmitted: sample.sample_metadata.is_resubmitted)
    end

    qc_data
  end
end
