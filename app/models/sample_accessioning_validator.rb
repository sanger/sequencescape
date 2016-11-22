class SampleAccessioningValidator

  include ActiveModel::Validations

  attr_reader :sample, :current_user

  validate :check_accession_number, :check_metadata, :check_studies_are_suitable
  validates_presence_of :current_user

  def initialize(sample)
    @sample = sample
    @current_user = User.find_by_api_key(configatron.accession_local_key)
  end

  private

  def check_accession_number
    if sample.sample_metadata.sample_ebi_accession_number.present?
      errors.add(:sample, "has already been accessioned")
    end
  end

  def check_metadata
    unless sample.sample_metadata.sample_taxon_id.present? && sample.sample_metadata.sample_common_name.present?
      errors.add(:sample, "should have associated metadata - taxon id and common name")
    end
  end

  def check_studies_are_suitable
    unless studies_are_suitable?
      errors.add(:sample, "studies are not suitable")
    end
  end

  def studies_are_suitable?
    sample.studies.any? do |study|
      ([ Study::DATA_RELEASE_STRATEGY_OPEN, Study::DATA_RELEASE_STRATEGY_MANAGED ].include?(study.study_metadata.data_release_strategy)) && 
      ((Study::DATA_RELEASE_TIMINGS).include?(study.study_metadata.data_release_timing))
    end
  end
end