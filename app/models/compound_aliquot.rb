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

  attr_accessor :request, :source_aliquots

  attr_reader :component_samples, :compound_sample

  validate :tag_depth_is_unique

  def initialize(attributes)
    super

    @component_samples = source_aliquots.map(&:sample)
  end

  # Check that the component samples in the compound sample will be able to be distinguished -
  # this is represented by them all having a unique 'tag_depth'
  def tag_depth_is_unique
    return unless source_aliquots.pluck(:tag_depth).uniq!

    errors.add("#{DUPLICATE_TAG_DEPTH_ERROR_MSG}: #{component_samples.map(&:name)}")
  end

  def default_library_type
    source_aliquots.first.library_type
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
      library_id: copy_library_id,
      sample: compound_sample
    }
  end

  # Default study that the new compound sample will use
  # Uses the one from the request if it's present,
  # otherwise, the one from the source aliquots if it's consistent.
  def default_compound_study
    request.initial_study ||
      begin
        raise MULTIPLE_STUDIES_ERROR_MSG if studies.count > 1

        studies.first
      end
  end

  def studies
    source_aliquots.map(&:study).uniq
  end

  # Default project that the new compound sample will use
  # Uses the one from the request if it's present,
  # otherwise, one grabbed from a source aliquot.
  def default_compound_project_id
    request.initial_project_id || source_aliquots.first.project_id
  end

  # If the library_id is the same on all source aliquots, we can confidently transfer it to the target aliquot
  # How the library_id should be set if the source aliquots have different library_ids is not defined
  # Therefore, set it to nil for now, until we have a real requirement
  def copy_library_id
    library_ids = source_aliquots.map(&:library_id).uniq
    library_ids.size == 1 ? library_ids.first : nil
  end

  def tag_id
    source_aliquots.first.tag_id
  end

  def tag2_id
    source_aliquots.first.tag2_id
  end
end
