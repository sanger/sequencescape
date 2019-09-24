class DataReleaseStudyType < ApplicationRecord
  extend Attributable::Association::Target

  has_many :study

  validates :name,
            presence: true,
            uniqueness: { message: 'of data release study type already present in database', case_sensitive: false }

  scope :assay_types, -> { where(is_assay_type: true) }
  scope :non_assay_types, -> { where(is_assay_type: false) }

  DATA_RELEASE_TYPES_SAMPLES = ['genotyping or cytogenetics'].freeze
  DATA_RELEASE_TYPES_STUDIES = [].freeze

  def is_not_specified?
    false
  end

  def studies_excluded_for_release?
    DATA_RELEASE_TYPES_STUDIES.include?(name)
  end

  def samples_excluded_for_release?
    DATA_RELEASE_TYPES_SAMPLES.include?(name)
  end

  def self.default
    find_by(is_default: true)
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :data_release_study_type_id
      base.belongs_to :data_release_study_type
    end
  end
end
