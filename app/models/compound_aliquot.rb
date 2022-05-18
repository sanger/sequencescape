# frozen_string_literal: true

# Factory class for creating Aliquots with compound samples in them.
# At time of writing, called from Request::SampleCompoundAliquotTransfer, in the context of a Request.
#
# The inputs are:
#   request           A Request for transferring source_aliquots into a target receptacle.
#                     At time of writing, only used for a SequencingRequest, from a multiplex tube into a lane.
#   source_aliquots   A list of Aliquots that should be transferred into a single Aliquot in a target Receptacle,
#                     that containes  contain a single compound sample.
#                     The list of component samples is derived from source_aliquots.
#                     Some attributes are transferred from the source aliquots onto the compound aliquot.
#
class CompoundAliquot
  include ActiveModel::Model

  DUPLICATE_TAG_DEPTH_ERROR_MSG = "Cannot create compound sample from following samples due to duplicate 'tag depth'"
  MULTIPLE_STUDIES_ERROR_MSG =
    'Cannot create compound sample due to the component samples being under different studies.'
  MULTIPLE_PROJECTS_ERROR_MSG =
    'Cannot create compound sample due to the component samples being under different projects.'

  attr_accessor :request, :source_aliquots, :compound_sample

  attr_reader :component_samples

  validate :tag_depth_is_unique
  validate :source_aliquots_have_same_study
  validate :source_aliquots_have_same_project

  def initialize(attributes)
    super

    @component_samples = source_aliquots.map(&:sample)
  end

  # Check that the component samples in the compound sample will be able to be distinguished -
  # this is represented by them all having a unique 'tag_depth'
  def tag_depth_is_unique
    return unless source_aliquots.pluck(:tag_depth).uniq!

    errors.add(:base, "#{DUPLICATE_TAG_DEPTH_ERROR_MSG}: #{component_samples.map(&:name)}")
  end

  def source_aliquots_have_same_study
    return if request.initial_study || source_aliquots.map(&:study_id).uniq.count == 1

    errors.add(:base, "#{MULTIPLE_STUDIES_ERROR_MSG}: #{component_samples.map(&:name)}")
  end

  def source_aliquots_have_same_project
    return if request.initial_project || source_aliquots.map(&:project_id).uniq.count == 1

    errors.add(:base, "#{MULTIPLE_PROJECTS_ERROR_MSG}: #{component_samples.map(&:name)}")
  end

  # Generates the compound sample, under the default study, using the component samples
  def create_compound_sample
    @compound_sample =
      default_compound_study.samples.create!(
        name: SangerSampleId.generate_sanger_sample_id!(default_compound_study.abbreviation),
        component_samples: component_samples
      )
  end

  def aliquot_attributes
    {
      tag_id: tag_id,
      tag2_id: tag2_id,
      library_type: default_library_type,
      study_id: default_compound_study.id,
      project_id: default_compound_project_id,
      library_id: default_library_id,
      sample: compound_sample
    }
  end

  # Study & Project:
  # Use the one from the request if present,
  # Otherwise use the one from the source aliquots if it's consistent
  # Error if inconsistent (see validation)
  def default_compound_study
    request.initial_study || source_aliquots.first.study
  end

  def default_compound_project_id
    request.initial_project_id || source_aliquots.first.project_id
  end

  # Less dangerous attributes:
  # Use the one from the source aliquots if it's consistent
  # Otherwise, set it to nil for now, as the behaviour hasn't been specified if it's inconsistent
  def default_library_type
    library_types = source_aliquots.map(&:library_type).uniq
    library_types.size == 1 ? library_types.first : nil
  end

  def default_library_id
    library_ids = source_aliquots.map(&:library_id).uniq
    library_ids.size == 1 ? library_ids.first : nil
  end

  # Tags:
  # We can assume that the tags will be the same for all source aliquots,
  # as that's essentially the definition of a compound sample - they all have the same
  # tag1 and tag2 but different tag_depths.
  def tag_id
    source_aliquots.first.tag_id
  end

  def tag2_id
    source_aliquots.first.tag2_id
  end
end
