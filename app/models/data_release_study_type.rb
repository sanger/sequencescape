# On {Study} creation the user selects a {DataReleaseStudyType} from a drop down list
# of pre-registered data release study types. The default option is determined by the
# {#is_default} flag in the database
#
# This information is exposed:
#
# - In the warehouses, where it *may* be used by customers, NPG, or bioinformaticians
# - Via the V1 API. (Not aware of any uses here, but there may be)
#
# It drives specific behaviours:
# - Shows the array express accession field on study edit page if {#for_array_express} is true
# - Determines if the <ArrayExpress> tag is added to the study accession
# - Determines the list of valid delay reasons
#
# @see StudyType
class DataReleaseStudyType < ApplicationRecord
  extend Attributable::Association::Target

  # @!attribute is_default
  #   Should be true for single option, sets it as the default DataReleaseStudyType
  #   @return [Boolean] True if a default, false otherwise
  # @!attribute for_array_express
  #   Determines if the study needs an ArrayExpress accession number and adds an <ArrayExpress> tag to the study.xml.
  #   (This used to trigger generation of an ArrayExpress accession, but I'm not sure this is still the case)
  #   @return [Boolean] True if the associated study needs ArrayExpress accession numbers
  # @!attribute is_assay_type
  #   Controls whether 'assay of no other use' as acceptable reason for a delay in data-release
  #   in app/views/shared/metadata/edit/_study.html.erb
  #   @return [Boolean] True if 'assay of no other use' is a valid delay reason

  has_many :study

  validates :name,
            presence: true,
            uniqueness: { message: 'of data release study type already present in database', case_sensitive: false }

  scope :assay_types, -> { where(is_assay_type: true) }
  scope :non_assay_types, -> { where(is_assay_type: false) }

  #
  # Returns the default DataReleaseStudyType according to the is_default flag.
  #
  # @return [DataReleaseStudyType] The default DataReleaseStudyType for new studies
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
