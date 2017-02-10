# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2013,2014 Genome Research Ltd.
class ::Sample
  # This returns all samples that require an accession number to be generated based on the conditions of their
  # studies and themselves.  It comes from a long (and highly frustrating) experience of decoding the
  # app/models/data_release.rb logic.
  scope :requiring_accession_number, ->() {
    joins([
      'INNER JOIN study_samples ON samples.id = study_samples.sample_id',
      'INNER JOIN studies ON studies.id = study_samples.study_id',
      'LEFT JOIN sample_metadata AS tcnan_sm ON samples.id = tcnan_sm.sample_id',
      'LEFT JOIN study_metadata AS trea_sm ON trea_sm.study_id = studies.id',
      'LEFT JOIN data_release_study_types AS trea_drst ON trea_drst.id = trea_sm.data_release_study_type_id'
    ])
    .readonly(false)
    .where(["
      (tcnan_sm.sample_ebi_accession_number IS NULL OR TRIM(tcnan_sm.sample_ebi_accession_number) = '') AND
      (tcnan_sm.sample_taxon_id IS NOT NULL) AND
      (tcnan_sm.sample_common_name IS NOT NULL AND TRIM(tcnan_sm.sample_common_name) != '') AND

      trea_sm.data_release_strategy IN (:data_release_managed_or_open) AND
      studies.enforce_accessioning = TRUE AND NOT (
        (
          studies.enforce_data_release = FALSE OR NOT (
            ((trea_sm.data_release_timing IS NULL) OR (trea_sm.data_release_timing IS NOT NULL AND TRIM(trea_sm.data_release_timing) = ''))
          )
        ) AND (
          trea_drst.name IN (:data_release_study_type) OR
          trea_sm.data_release_timing IN (:data_release_timing)
        )
      )
    ", {
      data_release_timing: ['never', 'delayed'],
      data_release_study_type: DataReleaseStudyType::DATA_RELEASE_TYPES_SAMPLES,
      data_release_managed_or_open: [Study::DATA_RELEASE_STRATEGY_OPEN, Study::DATA_RELEASE_STRATEGY_MANAGED]
    }])
  }
end

# Only ever process those samples that actually need an accession number to be generated for them.
current_user = User.find_by(api_key: configatron.accession_local_key) or raise StandardError, 'Cannot find accessioning user'
Sample.requiring_accession_number.includes(:sample_metadata, studies: :study_metadata).find_each do |sample|
  begin
    sample.validate_ena_required_fields!
    sample.accession_service.submit_sample_for_user(sample, current_user) unless sample.accession_service.nil?
  rescue ActiveRecord::RecordInvalid => exception
    # warn "Please fill in the required fields for sample: #{sample.name}"
  rescue AccessionService::NumberNotRequired => exception
    # warn "An accession number is not required for this study.  Study name: #{sample.study.name}"
  rescue AccessionService::NumberNotGenerated => exception
    warn 'No accession number was generated'
  rescue AccessionService::AccessionServiceError => exception
    warn exception.message
  end
end
