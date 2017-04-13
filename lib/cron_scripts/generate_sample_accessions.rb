# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2011,2013,2014,2016 Genome Research Ltd.
class ::Sample
  # This returns all samples that require an accession number to be generated based on the conditions of their
  # studies and themselves.  It comes from a long (and highly frustrating) experience of decoding the
  # app/models/data_release.rb logic.

  # We can't just join on studies, as this messes up rails subsequent eager loading,
  # and studies that don't meet the criteria won't be loaded. This causes issues if
  # we have non-accessioned EGA studies, and an accessioned ENA study. This would result
  # in mistaken accessioning to the ENA as the EGA studies would not get loaded.
  scope :in_suitable_studies, ->() {
    joins([
      'INNER JOIN study_samples AS iss_ss ON iss_ss.sample_id = samples.id',
      'INNER JOIN study_metadata AS iss_sm ON iss_sm.study_id = iss_ss.study_id',
    ]).where('iss_sm.study_ebi_accession_number <> ""')
      .where(iss_sm: { data_release_strategy: [Study::DATA_RELEASE_STRATEGY_OPEN, Study::DATA_RELEASE_STRATEGY_MANAGED], data_release_timing: Study::DATA_RELEASE_TIMINGS }).uniq
  }

  scope :with_taxon_and_common_name, ->() {
    includes(:sample_metadata)
      .where('sample_metadata.sample_taxon_id IS NOT NULL')
      .where('sample_metadata.sample_common_name <> ""')
  }

  scope :requiring_accession_number, ->() {
    without_accession.in_suitable_studies.with_taxon_and_common_name
  }

  scope :with_required_data, ->() {
    select('samples.*').preload(:sample_metadata, studies: :study_metadata)
  }
end

# Only ever process those samples that actually need an accession number to be generated for them.
current_user = User.find_by(api_key: configatron.accession_local_key) or raise StandardError, 'Cannot find accessioning user'
Sample.requiring_accession_number.includes(:sample_metadata, studies: :study_metadata).find_each do |sample|
  begin
    next unless sample.accession_service.operational
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
